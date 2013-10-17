<?php
$save_folder = "./audio";
echo $save_folder;
if(! file_exists($save_folder)) {
  if(! mkdir($save_folder)) {
    die("failed to create save folder $save_folder");
  }
 }


$key = 'filename';
$tmp_name = $_FILES["upload_file"]["tmp_name"][$key];
$upload_name = $_FILES["upload_file"]["name"][$key];
$type = $_FILES["upload_file"]["type"][$key];
$newname = time().$upload_name;
$filename = "$save_folder/$newname";
$saved = 0;
//if($type == 'audio/x-wav' && preg_match('/^[a-zA-Z0-9_\-]+\.mp3$/', $upload_name) ) {
  $saved = move_uploaded_file($tmp_name, $filename) ? 1 : 0;
 //}

if($_POST['format'] == 'json') {
  header('Content-type: application/json');
  print "{\"saved\":$saved}";
 } else {
  print $saved ? "Saved" : 'Not saved';
 }

exit;
?>
