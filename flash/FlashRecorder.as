package {
  import flash.display.Sprite;
  import flash.external.ExternalInterface;
  import flash.events.MouseEvent;
	import flash.display.SimpleButton;
	import flash.net.FileReference;
  public class FlashRecorder extends Sprite {
	  
	  
	  public var logger:Logger;
	  public var recorder:Recorder;
	  
    public function FlashRecorder() {
      
      logger = new Logger();
      //ExternalInterface.addCallback("debugLog", logger.debugLog);
      recorder = new Recorder(logger);
      //recorder.addExternalInterfaceCallbacks();
	  
	 record_bt.addEventListener(MouseEvent.CLICK,recorddeal);
	 stop_bt.addEventListener(MouseEvent.CLICK,stopdeal);
	 play_bt.addEventListener(MouseEvent.CLICK,playdeal);
	 save_bt.addEventListener(MouseEvent.CLICK,savedeal);
	 
    }
 
  
  
  
 		private function recorddeal(e:MouseEvent) {
			
			recorder.record();
		}
		
		
		
 		private function stopdeal(e:MouseEvent) {
			
			recorder.stop();
			
		}
		private function playdeal(e:MouseEvent) {
			
			recorder.playmp3();
			
		}
		private function savedeal(e:MouseEvent) {
			
			 var _file = new FileReference();
			_file.save(recorder._mp3encoder.mp3Data, "recorded.mp3");
			
		}
		
		
		
		
  
  
  
  }
  
  
}