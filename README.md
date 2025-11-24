> [!NOTE]
> **This tool is currently in active development.** The base functionalities work but we are working on adding more feature and polishing the overall experience.

## 🗒️ Preambule

#### The problem this tool tries to solve.

A major bottleneck for every Ruby developers when running `bundle install` is the compilation of native gem extensions. To illustrate this issue, running `bundle install` on a new Rails application takes around **25 seconds** on a MacBook Pro M4, and 80% of that time is spent compiling the couple dozens of gems having native extensions. It would take only 5 seconds if it wasn't for the compilation.

#### How we can solve this problem for the Ruby community.

The Python community had exactly the same issue and came up with the amazing [cibuildwheel](https://github.com/pypa/cibuildwheel) solution to provide a CI based compilation approach to help maintainers ship their libraries will precompiled binaries for various platforms.

This tool modestly tries to follow the same approach by helping ruby maintainers ship their gems with precompiled binaries.

#### Existing solutions.

Precompilation isn't new in the Ruby ecosystem and some maintainers have been releasing their gems with precompiled binaries to speedup the installation process since a while (e.g. [nokogiri](https://rubygems.org/gems/nokogiri), [grpc](https://rubygems.org/gems/grpc), [karafka-rdkafka](https://rubygems.org/gems/karafka-rdkafka)). One of the most popular tool that enables to precompile binaries for different platform is the great [rake-compiler-dock](https://github.com/rake-compiler/rake-compiler-dock) toolchain.
It uses a cross compilation approach by periodically building docker images for various platforms and spinning up containers to compile the binaries.

As noted by @flavorjoes, this toolchain works great but it's complex and brittle compared to the more simple process of compiling on the target platform.

## 💻 Easy Compile

> [!NOTE]
> Easy Compile is for now not able to compile projects that needs to link on external libraries. Unless the project vendors those libraries or uses [mini_portile](https://github.com/flavorjones/mini_portile).

> [!IMPORTANT]
> Repositories hosted on GitHub organization that don't belong to Shopify can't be tested at the moment. This is a temporary limitation that will be lifted
> once we opensource this tool and publish its associated GitHub action.
>
> You can either fork the repo inside the shopify-playground org or you can ping me (@edouard-chin) and I'll help you set it up.


### How to use it

While Easy Compile is generally **not** meant to be used locally, it provides a command to generate the right GitHub workflow for your project:

1. Install Easy Compile: `git clone https://github.com/shopify-playground/edouard-playground`, `cd edouard-playground && rake install`
2. Generate the workflow: `cd` in your gem's folder and run `easy_compile ci_template`
3. Commit the `.github/gem-compile.yaml` file.

### Triggering the workflow

Once pushed in your repository **default** branch, the workflow that we just generated is actionable manually on the GitHub action page. It will run in sequence:

1. Compile the gem on the target platform (defaults to MacOS ARM, MacOS Intel, Windows, Ubuntu 24)
2. Once the compilation succeeds on all platform, it proceeds to run the test suite on the target platform. This will trigger many CI steps as the testing matrix is big.
3. Once the test suite passes for all platforms and all Ruby versions the gem is compatible with, the action proceeds to installing the gem we just packaged. This step ensure that the gem is actually installable.
4. [OPTIONAL] When trigering the workflow manually, you can tick the box to automatically release the gems that were packaged. This works using the RubyGems trusted publisher feature (documentation to write later). If you do no want the tool to make the release, you can download all the GitHub artifacts that were uploaded. It will contain all the gems with precompiled binaries in the `pkg` folder. You are free to download them locally and release them yourself from your machine.


### Changes to make in your gem to support precompiled binaries

Due to the RubyGems specification, we can't release a gem with precompiled binaries for a specific Ruby version. Because the Ruby ABI is incompatible between minor versions, Rake Compiler (the tool underneath Easy Compile), compiles the binary for every minor Ruby versions your gem supports. All those binaries will be packaged in the gem (called a fat gem) in different folder such as `3.0/date.so`, `3.1/date.so` etc...
At runtime, your gem need to require the right binary based on the running ruby version.

```ruby
# Before

require 'date_core.so'

# After

begin
  ruby_version = /(\d+\.\d+)/.match(::RUBY_VERSION)
  require "#{ruby_version}/date_core"
rescue LoadError
  # It's important to leave for users that can not or don't want to use the gem with precompiled binaries.
  require "date_core"
end
```

### Supported platforms/Ruby versions

|         | MacOS Intel  | MacOS ARM | Windows x64 UCRT | Linux GNU x86_64|Linux AARCH64 |
|---------|------------- | --------- | ------------|-----------------|-----------------|
| Ruby 3.0| 🟢           | 🟢        | 🟢          | 🟢             | 🟢             |
| Ruby 3.1| 🟢           | 🟢        | 🟢          | 🟢             | 🟢             |
| Ruby 3.2| 🟢           | 🟢        | 🟢          | 🟢             | 🟢             |
| Ruby 3.3| 🟢           | 🟢        | 🟢          | 🟢             | 🟢             |
| Ruby 3.4| 🟢           | 🟢        | 🟢          | 🟢             | 🟢             |

## 🧪 Development

If you'd like to run a end-to-end test, the `date` gem is vendored in this project. You can trigger a manual run to do the whole compile, test, install dance from the GitHub action menu.

<img width="1350" height="225" alt="Image" src="https://github.com/user-attachments/assets/e34946d8-aff2-4aac-92c0-108f1d5beda0" />
