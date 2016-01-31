# ShrinkMap

ShrinkMap is VIM plug-in to show shrinked current buffer in the sidebar.
The screenshot is:

![Screenshot](../image/shrinkmap.png)

## Features

ShrinkMap has features of:

* Shrinking the current buffer using [Braille patterns](https://en.wikipedia.org/wiki/Braille_Patterns)
* Highlighting lines of the current window in the sidebar
* Scrolling the current buffer by clicking the sidebar
* Scaling lines horizontally for speed and to save window width
* Drawing only the sidebar viewport for performance
* Lazy drawing for speed

## Commands and Keymaps

The following commands and keymaps are available:

| Command           | Keymap | Description                     |
|-------------------|--------|---------------------------------|
| `ShrinkMapToggle` | \\ss   | Open or Close ShrinkMap sidebar |
| `ShrinkMapOpen`   | \\so   | Open ShrinkMap sidebar          |
| `ShrinkMapClose`  | \\sc   | Close ShrinkMap sidebar         |
| `ShrinkMapUpdate` | \\su   | Draw [Braille patterns](https://en.wikipedia.org/wiki/Braille_Patterns) to ShrinkMap sidebar and highlight the current window in ShinkMap sidebar |

Note that "\\" is a default `<Leader>` of VIM.
If you changed it with `mapleader` in `${HOME}/.vimrc`, use the key.

## Configuration

Write configuration to `${HOME}/.vimrc` as usual in VIM.
The following are configurable options:

```VimL
let g:shrinkmap_sidebar_width = 25 "Braille characters
" A Braille character has 2 dots in a width.

let g:shrinkmap_horizontal_shrink = 2 "characters drawn as a Braille dot
" A large number contributes drawing speed but loses expression.

let g:shrinkmap_lazy_limit_time  = 0.25 "sec

let g:shrinkmap_lazy_limit_count = 8 "times
" Suitable value is multiplied by g:shrinkmap_horizontal_shrink.

let g:shrinkmap_highlight_name = 'CursorLine'
"let g:shrinkmap_highlight_name = 'Visual'
```

## Contributing

1. Fork it ( https://github.com/ryujinno/shrinkmap.vim/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

ShinkMap is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
