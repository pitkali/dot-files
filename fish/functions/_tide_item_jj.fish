function _tide_item_jj
  if not jj log -r@ -n1 --no-graph --ignore-working-copy -T 'change_id.shortest()' 2>/dev/null | read -f change_id
    return
  end

  set -l stat (jj log -r@ -n1 --no-graph --ignore-working-copy -T 'diff.files().map(|i| i.status_char()).join("\n")' 2>/dev/null)
  string match -qr '(0|(?<added>.*))\n(0|(?<modified>.*))\n(0|(?<removed>.*))\n(0|(?<renamed>.*))' \
    "$(string match A $stat | count
       string match M $stat | count
       string match D $stat | count
       string match R $stat | count)"

  _tide_print_item jj 'jj '$change_id (echo -ns ' +'$added
    echo -ns ' ~'$modified
    echo -ns ' -'$removed
    echo -ns ' >'$renamed)
end
