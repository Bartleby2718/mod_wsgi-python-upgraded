# mod_wsgi-python-upgraded
Upgrades the Python version of https://github.com/GrahamDumpleton/mod_wsgi-docker

### **Motivation**
I really wanted to use Python 3.6+ because of [f-strings in Python 3.6](https://www.python.org/dev/peps/pep-0498/) and [`breakpoint()` in Python 3.7](https://www.python.org/dev/peps/pep-0553/). However, [mod_wsgi-docker](https://github.com/GrahamDumpleton/mod_wsgi-docker), which supported up to Python 3.5.4, is no longer being maintained. As such, I looked at [Graham Dumpleton's original mod_wsgi-docker repository](https://github.com/GrahamDumpleton/mod_wsgi-docker) and [Professor Pinckney's Dockerfile](https://github.com/thomaspinckney3/django-docker/blob/master/Dockerfile) to upgrade Python version.

### **Note**
- The `Dockerfile` is a superset of what was required to install Python 3.7.6 on Debian 8 (Jessie). I don't exactly know which of these would form a minimal set, but at least it works for me now.
-  You can modify `PYTHON_VERSION_MAJOR_MINOR` and `PYTHON_VERSION_PATCH` to suit your need. Note that you have to change them twice (in `RUN` command and in `ENV` command).

### **Tips, Tricks, and Troubleshooting**
1. Output redirection
  - Because the standard output is extremely long, I recommend redirecting the output to a text file, naming them with numbers, problems, and attempted solutions. This will help you go back to previous output and compare the differences.
2. `make` after `./configure`
  - Python `make` takes a very long time (50 minutes on my machine). Make sure your `./configure` (or OpenSSL `./config`) returns correct output before getting started on `make`.
3. `libreadline-gplv2-dev : Conflicts: libreadline-dev but 6.3-8+b3 is to be installed`
  - You might have installed these packages after searching in StackOverflow. Maybe this is because I built OpenSSL from source, but `libreadline-gplv2-dev` was unnecessary.
4. `The necessary bits to build these optional modules were not found` (In particular, `pip is configured with locations that require TLS/SSL, however the ssl module in Python is not available.`)
  - For anything besides `_ssl`, you can get away with `apt-get install`ing additional packages, googling what you exactly need.
  - If `_ssl` shows up, you might have seen the error message in the parentheses. First, check if you can install LibreSSL 1.0.2 or above with `apt-get install` (through `apt-cache madison openssl`) or `yum install`. I could only get 1.0.1, so I had to build from source. In that case, you need to make sure you check that the following three lines end with "yes"es when you run Python's `./configure`. If you don't see the three yes'es below, you need to check your OpenSSL (I've devoted an entire section on building OpenSSL from source.):
```
checking for openssl/ssl.h in YOUR_SSL_PATH_WHICH_I_DO_NOT_KNOW... yes
checking whether compiling and linking against OpenSSL works... yes
checking for X509_VERIFY_PARAM_set1_host in libssl... yes
```
5. Memory
  - I'm not sure if this helps, but allocating more resource to Docker or a VM might help. I didn't realize that I had allocated only 2GB to Docker Desktop.
6. Incremental commits
  - Now that I have finished refactoring, I think I should have broken down `Dockerfile` into multiple modular instructions because it helps speeds up the build process by using the cached layers.

### Building OpenSSL from source
- There is a [very useful tutorial on HowtoForge](https://www.howtoforge.com/tutorial/how-to-install-openssl-from-source-on-linux). Basically, it can be divided into a few steps:
0) Determine which version to download and temporarily set an environment variable. [Python 3.7 requires OpenSSL 1.0.2+](https://github.com/python/cpython/blob/43364a7ae01fbe4288ef42622259a0038ce1edcc/setup.py#L414), and it seems like [there was a small change in OpenSSL 1.1.0](https://wiki.openssl.org/index.php/Compilation_and_Installation).
1) `cd` into the directory you want to download OpenSSL tar file.
2) Use `wget` or `curl` to download the tar file.
3) Unzip the tar file and `cd` into the newly created directory
4) Run `./config` with necessary flags after you read the ['PREFIX_and_OPENSSLDIR' section of the link above](https://wiki.openssl.org/index.php/Compilation_and_Installation#PREFIX_and_OPENSSLDIR).
5) Run `make` and `make install`.
6) Run `./openssl version -a` to check the version of the newly installed OpenSSL.
Also, run `openssl version -a` if you have another OpenSSL installed already, just for comparison.
7) Add a shared object configuration file for OpenSSL, and verify that it can now be used by a linker.
8) Add the new OpenSSL binary to `PATH`, so that the new OpenSSL executable is called whenever `openssl` is called.
