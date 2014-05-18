## Installation using rbenv on OS X

Using instructions found http://robots.thoughtbot.com/using-rbenv-to-manage-rubies-and-gems
and http://dan.carley.co/blog/2012/02/07/rbenv-and-bundler/.  Here's how
to get started with rbenv on os x

    brew update
    brew install rbenv

Add the following lines to `.bashrc`:

    # Homebrew rbenv
    #To use Homebrew's directories rather than ~/.rbenv add to your profile:
    export RBENV_ROOT=/usr/local/var/rbenv
    if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi

Restart the shell and install

    brew install rbenv-gem-rehash
    brew install ruby-build

Restart the shell and then install the rubies

    rbenv install 2.0.0-p353
    rbenv global 2.0.0-p353

Install rbenv-bundler

    git clone git://github.com/carsomyr/rbenv-bundler.git /usr/local/var/rbenv/plugins/bundler

Install bundler

    gem update --system
    gem install bundler
    rbenv rehash

Configure bundler by adding the following to `~/.bundle/config`

    ---
    BUNDLE_PATH: vendor
    BUNDLE_DISABLE_SHARED_GEMS: "1"

Finally, move into the Remi directory and install gems

    bundle install
    rbenv rehash
