chunk-ex
========

Minecraft [Chunk Data](http://wiki.vg/SMP_Map_Format) implementation in Elixir

## Testing
Download the [1.9-pre3-1 test data](http://lunarco.de/minecraft/chunks/):
```sh
mkdir chunks; cd chunks
wget http://lunarco.de/minecraft/chunks/chunks-1.9.1-pre3-1.zip
unzip chunks-1.9.1-pre3-1.zip
```
Use `mix test` to compile and run the tests.

[![Build Status](https://travis-ci.org/Gjum/chunk-ex.svg?branch=master)](https://travis-ci.org/Gjum/chunk-ex)
