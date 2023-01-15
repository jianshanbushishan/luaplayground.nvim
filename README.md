## 概述
这个插件最初来源于[luapad](https://github.com/rafcamlet/nvim-luapad)，但是luapad的功能不是很满足自己的需求，在改造的过程中对其做了功能的删减和新加，最终重写了代码形成了新的luaplayground。

## 功能简介
- 一键打开或关闭playground（它会以浮动窗口的形式显示在窗口正中）
- playgroud上的代码会自动保存、并在下次打开时自动加载
- 支持自动运行（退出插入模式时）或手工运行（normal下按R键）
- playground代码中的报错和输出会以virtualtext的形式显示在对应代码的后面
- 支持以vim.notify的形式显示整个运行输出
- 支持设置自定义的初始化函数和脚本运行context
- 支持lua lsp

## 配置
lazy.nvim下的配置如下：
```lua
local M = {
  "jianshanbushishan/luaplayground.nvim",
  event = "VeryLazy",
  opts = {
    toggle_key = "<F5>",
    output = {
      virtual_text = true,
      notify = true,
    }
  },
  config = true,
}

return M
```

## 快捷键：
- <F5>: 打开或关闭playground
- R: 运行playground中的脚本
- <c-l>: 清除所有代码
- q: 彻底关闭playground

