# input is assumed to be an object
def decrypt($value):
  with_entries(if .value|type == "object"
    then with_entries(if .value | (type == "object" and has("$crypto"))
      then .value = $value else . end)
    else . end) ;

# walk was removed from jq@1.5
def walk(f):
  . as $in
  | if type == "object" then
      reduce keys[] as $key
        ( {}; . + { ($key):  ($in[$key] | walk(f)) } ) | f
  elif type == "array" then map( walk(f) ) | f
  else f
  end;

walk(if type == "object" then decrypt($cleartext) else . end)
