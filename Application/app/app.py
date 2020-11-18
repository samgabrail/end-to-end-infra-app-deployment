import os
import common.vault as vault
from environs import Env
from common.database import Database
from models.blog import Blog
from models.post import Post
from models.user import User


__author__ = 'SamG'


from flask import Flask, render_template, request, session, make_response

env = Env()
# Read .env into os.environ
env.read_env()

# Port variable to run the server on that you get from docker-compose
# below get pulled from .env file
PORT = env('PORT')

app = Flask(__name__)  # '__main__'
app.secret_key = "jose"


@app.route('/')
def home_template():
    return render_template('home.html')


@app.route('/login')
def login_template():
    return render_template('login.html')


@app.route('/register')
def register_template():
    return render_template('register.html')


@app.before_first_request
def initialize_database():
    Database.initialize()


@app.route('/auth/login', methods=['POST'])
def login_user():
    email = request.form['email']
    password = request.form['password']

    if User.login_valid(email, password):
        User.login(email)
        session['email'] = email
    else:
        return render_template("login.html")

    return render_template("profile.html", email=session['email'])


@app.route('/logout', methods=['GET'])
def logout_user():
    [session.pop(key) for key in list(session.keys())]

    return render_template("login.html")

@app.route('/auth/register', methods=['POST'])
def register_user():
    email = request.form['email']
    password = request.form['password']

    User.register(email, password)
    session['email'] = email

    return render_template("profile.html", email=session['email'])


@app.route('/blogs/<string:user_id>')
@app.route('/blogs')
def user_blogs(user_id=None):
    if not session:
        return render_template("login.html")

    if user_id is not None:
        user = User.get_by_id(user_id)
    else:
        user = User.get_by_email(session['email'])

    blogs = user.get_blogs()

    return render_template("user_blogs.html", blogs=blogs, email=user.email)


@app.route('/blogs/new', methods=['POST', 'GET'])
def create_new_blog():
    if not session:
        return render_template("login.html")

    if request.method == 'GET':
        return render_template('new_blog.html')
    else:
        title = request.form['title']
        description = request.form['description']
        user = User.get_by_email(session['email'])

        new_blog = Blog(user.email, title, description, user._id)
        new_blog.save_to_mongo()

        return make_response(user_blogs(user._id))


@app.route('/posts/<string:blog_id>')
def blog_posts(blog_id):
    blog = Blog.from_mongo(blog_id)
    posts = blog.get_posts()
    if Database.ENCRYPT:
        unencryptedPosts = []
        for post in posts:
            # print(f'here is one post:')
            # print(post)
            post.update({'content': vault.transit_decrypt(post['content'])})
            unencryptedPosts.append(post)
        return render_template('posts.html', posts=unencryptedPosts, blog_title=blog.title, blog_id=blog._id)
    else:
        return render_template('posts.html', posts=posts, blog_title=blog.title, blog_id=blog._id)



@app.route('/posts/new/<string:blog_id>', methods=['POST', 'GET'])
def create_new_post(blog_id):
    if request.method == 'GET':
        return render_template('new_post.html', blog_id=blog_id)
    else:
        title = request.form['title']
        content = request.form['content']
        user = User.get_by_email(session['email'])

        if Database.ENCRYPT:
            new_post = Post(blog_id, title, vault.transit_encrypt(content), user.email)
        else:
            new_post = Post(blog_id, title, content, user.email)
  
        new_post.save_to_mongo()     
        return make_response(blog_posts(blog_id))


if __name__ == '__main__':
    app.config['DEBUG'] = os.environ.get('ENV') == 'development' # Debug mode if development env
    app.run(host='0.0.0.0', port=int(PORT)) # Run the app