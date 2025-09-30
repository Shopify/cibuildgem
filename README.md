# EasyCompile

#### Summary

We'd like to improve the speed of `bundle install` as well as fixing a common source of failure for gems that have a native extension.

A way to solve this problem is helping maintainers shipping their gems with precompiled binaries with the right tooling. We want to take inspiration from the Python community and [cibuildhweel](https://github.com/pypa/cibuildwheel).


#### How does it work and what I have in mind

It's still a prototype at this point, but the idea is to piggyback on top of the existing great tooling such as `rake-compiler`. It provides a CLI that's able to compile a gem's extension by setting up the rake-compiler tasks itself and infer the right configuration based on the gem's gemspec.

Ultimately what I have in mind is to let developers write gems with extensions and run a single command `easy_compile compile test` to compile the gem and run its test suite without having to write boilerplate code.

If the tooling is reliable, the next step is to leverage CI machines and provide GitHub action templates and provide native compilation. The whole workflow would look something like:

1. Developer make a change on a branch, the GitHub action kicks in and spin up windows, macos or ubuntu machines, compile the gem and test that it works.
2. The change gets merged on main.
3. The gem maintainer wants to cut a release. He/she nagivates on the GitHub UI and manually run a workflow that this tool has setup.
  - The tool compile the gem and test it on various platforms. If all test passes, the action proceeds.
  - The tool package the gem.
  - The tool publish the gem with the provided user's credentials (That can be configured as a secret on GitHub)

#### Current features

- `easy_compile compile_and_test` -> Compile the gem extension and run the test suite
- `easy_compile clobber` -> Clobber the gem's compilation artifacts and binaries
- `easy_compile ci_template --rubies 3.4.4 --os macos-latest` -> Generate GitHub CI templates for running this tool on CI


#### Testing

This project has a dummy gem with a "hello world" C extension in the `test/fixtures` folder.
It's also possible to test on other gems with extensions locally, cd in the folder and run `easy_compile compile_and_test`

It's also possible to manually trigger a CI run using the GitHub UI and choosing the project to be tested on.

<img width="366" height="301" alt="Image" src="https://github.com/user-attachments/assets/ed2a0917-7708-471a-9262-e1499ada7375" />


--------------

For reference, this are all the gems with native extensions that a new Rails application depends on

| Gem name  | The tool works on it | Why it fails |
| ------------- | ------------- | ------------- |
| Bindex  | ✅   | Works but need to run `easy_compile --gemspec bindex.gemspec` because the gem has two gemspec at its root |
| websocket-driver  | ⚠️  | Compilation works but the gem doesn't provide a default Rake test command |
| racc  | ✅   | |
| debug  | ✅   | |
| erb  | ✅   | |
| bcrypt_pbkdf  | ✅   | |
| bootsnap  | ✅   | |
| psych  | ✅   | |
| ed25519  | ⚠️ | Compilation works but the gem doesn't provide a default Rake test command |
| nio4r  | ⚠️ | Compilation works but the gem doesn't provide a default Rake test command |
| io-console  | ✅   | |
| puma  | ✅   | |
| json  | ✅   | |
| date  | ✅   | |
| bigdecimal  | ✅   | |
| mysql2  | ✅   | |
| prism  | ✅   | |
| msgpack  | ⚠️ | Compilation works but the gem doesn't provide a default Rake test command |
