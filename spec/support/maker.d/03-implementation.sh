module locals log options controls filesystem portability text interaction date

# Prefer internal implementation when it exists!
if is_function "mg_$MG_APPNAME"; then
  "mg_$MG_APPNAME" "$@"
elif is_function "$MG_APPNAME"; then
  "$MG_APPNAME" "$@"
else
  fn=$1; shift
  if is_function "mg_$fn"; then
    "mg_$fn" "$@"
  elif is_function "$fn"; then
    "$fn" "$@"
  else
    die "Neither $MG_APPNAME nor $fn are functions of the mg.sh API"
  fi
fi
