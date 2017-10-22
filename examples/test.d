import std.stdio;
import argon.argon;

struct Content
{
  string hello_world = "Hello, World!";
  string[] list = ["alpha", "beta", "gamma", "delta"];
}

void main()
{
  Content content;
  stdout.renderArgonTemplate!("test.argon", "content", content)();
}