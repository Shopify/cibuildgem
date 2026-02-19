> [!NOTE]
> **This tool is currently in active development.** We are very much looking for your feedback.

## 🗒️ Preamble

#### The problem this tool tries to solve.

A major bottleneck for every Ruby developers when running `bundle install` is the compilation of native gem extensions. To illustrate this issue, running `bundle install` on a new Rails application takes around **25 seconds** on a MacBook Pro M4, and 80% of that time is spent compiling the couple dozens of gems having native extensions. It would take only 5 seconds if it wasn't for the compilation.

#### How we can solve this problem for the Ruby community.

The Python community had exactly the same issue and came up with the amazing [cibuildwheel](https://github.com/pypa/cibuildwheel) solution to provide a CI based compilation approach to help maintainers ship their libraries will precompiled binaries for various platforms.

This tool modestly tries to follow the same approach by helping ruby maintainers ship their gems with precompiled binaries.

#### Existing solutions.

Precompilation isn't new in the Ruby ecosystem and some maintainers have been releasing their gems with precompiled binaries to speedup the installation process since a while (e.g. [nokogiri](https://rubygems.org/gems/nokogiri), [grpc](https://rubygems.org/gems/grpc), [karafka-rdkafka](https://rubygems.org/gems/karafka-rdkafka)). One of the most popular tool that enables to precompile binaries for different platform is the great [rake-compiler-dock](https://github.com/rake-compiler/rake-compiler-dock) toolchain.
It uses a cross compilation approach by periodically building docker images for various platforms and spinning up containers to compile the binaries.

As noted by [@flavorjones](https://github.com/flavorjones), this toolchain works great but it's complex and brittle compared to the more simple process of compiling on the target platform.

## 💻 cibuildgem

Head to the [documentation Wiki](https://github.com/Shopify/cibuildgem/wiki) to setup and configure cibuildgem for your gem.

## Working examples

Here are some working examples on gem that have setup cibuildgem

| Name      | Example Run | Published Gem |
|-----------|-------------|---------------|
| [Rubydex](https://github.com/shopify/rubydex) | [CI Run](https://github.com/Shopify/rubydex/actions/runs/21880161517) | [Gem](https://rubygems.org/gems/rubydex/versions/0.1.0.beta4-arm64-darwin) |
| [Heap Profiler](https://github.com/shopify/heap-profiler) | [CI Run](https://github.com/Shopify/heap-profiler/actions/runs/20996043558) | [Gem](https://rubygems.org/gems/heap-profiler/versions/0.8.0.rc1-x86_64-linux) |
| [djb2](https://github.com/Shopify/djb2) | [CI Run](https://github.com/Shopify/djb2/actions/runs/22188688549) | [Gem](https://rubygems.org/gems/djb2/versions/0.1.1-x86_64-linux) |
| [Blake3](https://github.com/Shopify/blake3-rb) | [CI Run](https://github.com/Shopify/blake3-rb/actions/runs/21253662535) | [Gem](https://rubygems.org/gems/blake3-rb/versions/1.5.6.rc1-x86_64-linux) |
| [Raindrops (fork)](https://github.com/Edouard-chin/raindrops) | [CI Run](https://github.com/Edouard-chin/raindrops/actions/runs/22045845221) | [Gem](https://rubygems.org/gems/precompiled-raindrop) |
| [Stack Frames](https://github.com/Shopify/stack_frames) | [CI Run](https://github.com/Shopify/stack_frames/actions/runs/19969899178) | [Gem](https://rubygems.org/gems/stack_frames/versions/0.1.4-x86_64-linux) |

## Supported platforms/Ruby versions

|         | MacOS Intel  | MacOS ARM | Windows x64 UCRT | Linux GNU x86_64|Linux AARCH64 |
|---------|------------- | --------- | ------------|-----------------|-----------------|
| Ruby 3.1| 🟢           | 🟢        | 🟢          | 🟢             | 🟢             |
| Ruby 3.2| 🟢           | 🟢        | 🟢          | 🟢             | 🟢             |
| Ruby 3.3| 🟢           | 🟢        | 🟢          | 🟢             | 🟢             |
| Ruby 3.4| 🟢           | 🟢        | 🟢          | 🟢             | 🟢             |
| Ruby 4.0| 🟢           | 🟢        | 🟠 (not tested)| 🟢             | 🟢             |
