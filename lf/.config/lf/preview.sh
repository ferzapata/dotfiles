#!/bin/sh
#######################################################################
# LF - File Previewer
#######################################################################

set -Cfu

readonly WIDTH=$(($(tput cols) / 2))
readonly HEIGHT=$(($(tput lines) - 2))

preview_txt() {
  if command -v highlight >/dev/null; then
    highlight --force \
              --out-format=xterm256 \
              --replace-tabs=2 \
              --style=base16/ia-dark \
              -- "$1"
  elif command -v pygmentize >/dev/null; then
    pygmentize -- "$1"
  else
    cat -- "$1"
  fi
}

preview_pdf() {
  if command -v pdftotext >/dev/null; then
    pdftotext -l 8 -nopgbrk -q -- "$1" -
  else
    echo '(document)'
  fi
}

preview_img() {
  if command -v chafa >/dev/null; then
    chafa --colors 240 \
          --size ${WIDTH}x${HEIGHT} \
          --symbols ascii+vhalf+block+space \
          --font-ratio 5/12 \
          "$1"
  elif command -v magick >/dev/null; then
    magick identify -- "$1"
  else
    echo '(image)'
  fi
}

preview_snd() {
  if command -v ffmpeg >/dev/null; then
    readonly c=$(printf '\01')
    ffmpeg -hide_banner -v panic -i "$1" -f ffmetadata - \
    | grep -i '^\(artist\|title\|album\|date\)=' \
    | sed "s/=/$c/" \
    | column -t -s "$c" -o ' : '
  else
    echo '(audio)'
  fi
}

preview_vid() {
  if command -v ffmpeg >/dev/null; then
    ffmpeg -hide_banner -v panic -i "$1" -f image2 - | preview_img -
  else
    echo '(video)'
  fi
}

preview_arc() {
  if command -v atool >/dev/null; then
    atool --list -- "$1"
  elif command -v lsar >/dev/null; then
    lsar -- "$1"
  else
    echo '(archive)'
  fi
}

preview_sym() {
  readonly nf=$(readlink "$1")
  if [ $(file -b --mime-type -- "$nf") != 'inode/symlink' ]; then
    exec "$0" "$nf"
  else
    echo '(symlink)'
  fi
}

case $(file -b --mime-type -- "$1") in
  text/*)
    preview_txt "$1" ;;
  image/gif|video/*)
    preview_vid "$1" ;;
  image/*)
    preview_img "$1" ;;
  audio/*)
    preview_snd "$1" ;;
  application/*pdf)
    preview_pdf "$1" ;;
  application/x-archive|\
  application/x-cpio|\
  application/x-tar|\
  application/x-bzip2|\
  application/gzip|\
  application/x-lz*|\
  application/x-xz|\
  application/zstd|\
  application/x-7z*|\
  application/zip|\
  application/x-rar*|\
  application/x-gtar)
    preview_arc "$1" ;;
  inode/symlink)
    preview_sym "$1" ;;
  *)
    echo '(binary)'
esac
