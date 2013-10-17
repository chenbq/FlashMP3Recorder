package com.adobe.soundsEncoders
{
	import flash.events.ProgressEvent;
	import cmodule.shine.CLibInit;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.TimerEvent;
	import flash.net.FileReference;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getTimer;
	import fl.controls.TextArea;

	/**
	 * @author kikko.fr - 2010
	 */
	public class ShineMP3Encoder extends EventDispatcher 
	{
		
		public var wavData:ByteArray;
		public var mp3Data:ByteArray;
		
		private var cshine:Object;
		private var timer:Timer;
		private var initTime:uint;
		public var encoderArea:TextArea;
		public function ShineMP3Encoder(wavData:ByteArray,textarea:TextArea ) 
		{
			this.wavData = wavData;
			this.encoderArea = textarea;
		}

		public function EncoderMP3() : void 
		{
			
			initTime = getTimer();
			
			mp3Data = new ByteArray();
			
			
			timer = new Timer(1000/30);
			timer.addEventListener(TimerEvent.TIMER, update);
			
			var temp:CLibInit = new CLibInit();
			cshine = temp.init();
			cshine.init(this, wavData, mp3Data);
			
			if(timer) timer.start();
		}
		
		public function shineError(message:String):void 
		{
			
			timer.stop();
			timer.removeEventListener(TimerEvent.TIMER, update);
			timer = null;
			
			dispatchEvent(new ErrorEvent(ErrorEvent.ERROR, false, false, message));
		}
		
		public function saveAs(filename:String=".mp3"):void 
		{
			
			var ref:FileReference = new FileReference();
			ref.save(mp3Data, filename);
		}
		
		private function update(event : TimerEvent) : void 
		{
			
			var percent:int = cshine.update();
			dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, percent, 100));
			
			encoderArea.text = percent.toString()+'%';
			
			if(percent==100) {
				
				
				
				timer.stop();
				timer.removeEventListener(TimerEvent.TIMER, update);
				timer = null;
				
				dispatchEvent(new Event(Event.COMPLETE));
			}
		}
		
		
	}
}
