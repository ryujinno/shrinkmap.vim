# ShrinkMap.vim

[![Build Status](https://travis-ci.org/ryujinno/shrinkmap.vim.svg?branch=master)](https://travis-ci.org/ryujinno/shrinkmap.vim)

ShrinkMap.vim is VIM plug-in to show the current buffer in the sidebar with shrinking.
The screenshot is:

![Screenshot](https://raw.githubusercontent.com/ryujinno/shrinkmap.vim/master/image/shrinkmap.png)


## Features

ShrinkMap.vim has features of:

* Shrinking the current buffer using [Braille patterns](https://en.wikipedia.org/wiki/Braille_Patterns)
* Highlighting lines of the current window in the sidebar
* Jumping the current buffer by clicking the sidebar
* Scaling lines horizontally for speed and to save window width
* Drawing only the sidebar viewport for performance
* Lazy drawing for speed


## Commands and Keymaps

The following commands and keymaps are available:

| Command           | Keymap | Description                     |
|-------------------|--------|---------------------------------|
| `ShrinkMapToggle` | \\ss   | Open or close ShrinkMap sidebar |
| `ShrinkMapOpen`   | \\so   | Open ShrinkMap sidebar          |
| `ShrinkMapClose`  | \\sc   | Close ShrinkMap sidebar         |
| `ShrinkMapUpdate` | \\su   | Draw [Braille patterns](https://en.wikipedia.org/wiki/Braille_Patterns) to ShrinkMap sidebar and highlight the current window in ShinkMap sidebar |

Note that "\\" is a default `<Leader>` of VIM.
If you changed it with `mapleader` in `${HOME}/.vimrc`, use the key.


## Options

Write configuration to `${HOME}/.vimrc` as usual in VIM.
The following are configurable options:

<dl>
  <dt>g:shrinkmap_sidebar_align</dt>
  <dd>
      Alignment of sidebar window: "right", "left"
      Sidebar window applies for this value when open.
  </dd>
</dl>

```VimL
let g:shrinkmap_sidebar_align = 'right'
```


<dl>
  <dt>g:shrinkmap_sidebar_width</dt>
  <dd>
      Sidebar window width, which is max number of Braille characters in a line.
      A Braille character has 2 dots in a width.
      Sidebar window applies for this value when open and update.
  </dd>
</dl>

```VimL
let g:shrinkmap_sidebar_width = 25 "Braille characters
```


<dl>
  <dt>g:shrinkmap_horizontal_shrink</dt>
  <dd>
      Characters drawn as a Braille dot.
      A large number contributesdrawing speed but loses expression.
      ShrinkMap applies for this value when update.
  </dd>
</dl>

```VimL
let g:shrinkmap_horizontal_shrink = 2 "characters in a Braille dot
```


<dl>
  <dt>g:shrinkmap_highlight_name</dt>
  <dd>Name of higilighting the current window in ShrinkMap sidebar.
      "CursorLine", "Visual" and so on. Refer to :highlight command.
      ShrinkMap applies for this value when update.
  </dd>
</dl>

```VimL
let g:shrinkmap_highlight_name = 'CursorLine'
```


<dl>
  <dt>g:shrinkmap_lazy_limit_time</dt>
  <dd>
      Limit second for lazy drawing.
  </dd>
</dl>

```VimL
let g:shrinkmap_lazy_limit_time  = 0.25 "second
```


## Contributing

1. Fork it ( https://github.com/ryujinno/shrinkmap.vim/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


## License

ShinkMap.vim is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

