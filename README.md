# mod_wsgi-python-upgraded
- Run your Django server with `mod_wsgi-express start-server` on Debian 10 using Python 3.6+!
- The Docker image can be found [here](https://hub.docker.com/repository/docker/bartleby2718/mod_wsgi-python-upgraded/tags). Choose the Python version you want.

### **Motivation**
I really wanted to use Python 3.6+ for a school project because of [f-strings in Python 3.6](https://www.python.org/dev/peps/pep-0498/) and [`breakpoint()` in Python 3.7](https://www.python.org/dev/peps/pep-0553/). However, [mod_wsgi-docker](https://github.com/GrahamDumpleton/mod_wsgi-docker), which supported up to Python 3.5.4, is no longer being maintained. As such, I looked at [Graham Dumpleton's original mod_wsgi-docker repository](https://github.com/GrahamDumpleton/mod_wsgi-docker) and [Professor Pinckney's Dockerfile](https://github.com/thomaspinckney3/django-docker/blob/master/Dockerfile) to upgrade Python version. After the project was over, I have refactored the `Dockerfile` so that the image is only 6% bigger than the [original image](https://hub.docker.com/r/grahamdumpleton/mod-wsgi-docker) by @GrahamDumpleton. Mine is now based on Debian 10 `buster` (instead of Debian 8 `jessie`) and significantly easier to understand as it extends the [official Apache httpd image](https://hub.docker.com/_/httpd). Huge thanks to @GrahamDumpleton!

### **Note**
- The `Dockerfile` is likely a superset of what was required to build Python 3.6+. I don't exactly know which of these would form a minimal set, but at least it works for me now.
-  You can modify `PYTHON_VERSION_MAJOR_MINOR`, `PYTHON_VERSION_PATCH`, and `MOD_WSGI_VERSION` to suit your need using the [`--build-arg`](https://docs.docker.com/engine/reference/commandline/build/#set-build-time-variables---build-arg) option when you build this `Dockerfile`.

### **Tips, Tricks, and Troubleshooting**
Some of the remarks below are no longer relevant, but I'll keep it as it can be of help to someone.
1. Output redirection
  - Because the standard output of `docker build` is extremely long, I recommend redirecting the output to a text file, starting with indices and a short description of the problem or an attempted solution. This will help you go back to previous output and compare the differences.
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
  - Now that I have finished refactoring, I think I should have broken down `Dockerfile` into multiple modular instructions because it helps speeds up the build and debugging process by using the cached layers. Once you're all done, you can concatenate them back.
  - Now that I have finished refactoring, I think I should have broken down `Dockerfile` into multiple modular instructions because it helps speeds up the build process by using the cached layers.
7. `--enable-optimizations`
  - With this flag, it takes longer to build but yields a significant speed boost, according to [this StackOverflow answer](https://stackoverflow.com/questions/41405728/what-does-enable-optimizations-do-while-compiling-python). A caveat is that this does not work with old versions of GCC. Before refactoring, I had to take out the flag because Debian 8 `jessie` has GCC 4.9 by default.

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
