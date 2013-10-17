
	
package {
  import flash.display.Sprite;
  import flash.external.ExternalInterface;
  import flash.events.MouseEvent;
	import flash.display.SimpleButton;
	
  public class FlashRec extends Sprite {
	  
	  
	  var logger:Logger;
	  var recorder:Recorder;
	  
    public function FlashRecorder() {
      
      logger = new Logger();
      ExternalInterface.addCallback("debugLog", logger.debugLog);
      recorder = new Recorder(logger);
      recorder.addExternalInterfaceCallbacks();
	  
	  enabledBtn(record_bt,recorddeal);
	  enabledBtn(stop_bt,stopdeal);
	  enabledBtn(play_bt,playdeal);
	  enabledBtn(save_bt,savedeal);
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
			
			_file = new FileReference();
			_file.save(recorder._mp3encoder.mp3Data, "recorded.mp3");
			
		}
		
		
		
		//button操作
		private function enabledBtn(btn:SimpleButton,lis) {
			btn.addEventListener(MouseEvent.CLICK, lis);
			btn.enabled = true;
		}
		private function disabledBtn(btn:SimpleButton,lis) {
			btn.removeEventListener(MouseEvent.CLICK, lis);
			btn.enabled = false;
		}
		
  
  
  
  }
  
  
}
