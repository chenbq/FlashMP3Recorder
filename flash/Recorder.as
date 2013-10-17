package 
{


	//加入Sprite内容
	import flash.display.Sprite;
	// import flash.external.ExternalInterface;
	import flash.events.MouseEvent;
	import flash.display.SimpleButton;
	import flash.net.FileReference;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;

	/**
	
	2013.10.4.0:36开始大改
	*/
 	import flash.net.URLRequest;
	import flash.net.URLLoader;
	import MultiPartFormUtil;//构造URL和POST单元类
	import com.adobe.audio.format.WAVWriter;
	import com.adobe.audio.mp3.MP3Parser;//解析MP3，并播放
	//加入编码库
	import com.adobe.soundsEncoders.ShineMP3Encoder;//mp3编码器
	import com.adobe.soundsEncoders.WaveEncoder;//wav编码器
	import flash.events.TimerEvent;
	import flash.events.Event;
	import flash.events.ErrorEvent;
	import flash.events.SampleDataEvent;
	import flash.external.ExternalInterface;
	import flash.media.Microphone;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.system.Capabilities;
	import flash.utils.ByteArray;
	import flash.utils.getTimer;
	import flash.utils.Timer;
	import flash.events.MouseEvent;
	import flash.system.Security;
	import flash.system.SecurityPanel;
	import flash.events.StatusEvent;
	import flash.utils.getQualifiedClassName;
	import flash.net.FileReference;
	//import mx.collections.ArrayCollection;

	import ru.inspirit.net.MultipartURLLoader;


	public class Recorder extends Sprite
	{

		

		protected var isRecording:Boolean = false;
		protected var isPlaying:Boolean = false;
		protected var microphoneWasMuted:Boolean;
		protected var playingProgressTimer:Timer;
		protected var microphone:Microphone;
		protected var buffer:ByteArray = new ByteArray();
		protected var _file:FileReference;
		protected var wavbuffer:ByteArray = new ByteArray();

		protected var sound:Sound;
		protected var channel:SoundChannel;
		
		public var uploadFieldName:String;
		public var uploadUrl:String;
		//上传相关参量设置
		public var FileName:String;
		public var URLpost:String;
		public var uploadFormData:Array;
		
		var duration:int;//录音时长
		
		var timer:Timer=new Timer(1000);
		var timecount:int=0;
		var timermic:Timer=new Timer(10);
		
		

		public var _mp3encoder:ShineMP3Encoder;
		protected var _wavencoder:WaveEncoder;

		protected var mp3parser:MP3Parser;

		protected var recordingStartTime = 0;
		protected static var sampleRate = 44.1;


		//转换时间计算
		protected var encoderStartTime = 0;

		protected var encoderDurationTime = 0;
		
		
		/**加入音量指示器
		*/
		
		//var audioInd:Indicator = new Indicator(100,10,0x000000,0xffffff);
		//构造函数
		public function Recorder()
		{
			encoderArea.visible = false;
			ExternalInterface.addCallback("SetURL", this.SetURL);//设置上传参量
			ExternalInterface.addCallback("SetFilename", this.SetFilename);//设置文件名
			ExternalInterface.addCallback("SetPair", this.SetPair);//设置form表格
			//加入按键的监听
			this.uploadFormData = new Array();
			record_bt.addEventListener(MouseEvent.CLICK,recorddeal);
			stop_bt.visible=false;
			record_bt.visible=true;
			//addChild(audioInd);
			
		}
		

		public function SetURL(urlin:String):void{
			
			
			this.URLpost = urlin;
			timeArea.text = this.URLpost;
		}
		
		public function SetFilename(namein:String):void{
			
			
			this.FileName = namein;
			timeArea.text = this.FileName;
		}
		public function SetPair(date:String,datevalue:String):void{
			
			this.uploadFormData.push(MultiPartFormUtil.nameValuePair(date, datevalue))
		}
		/**加入按键的处理，录音按键
		*/
		private function recorddeal(e:MouseEvent)
		{
		timecount = 0;//录音时间致零
			
		record_bt.removeEventListener(MouseEvent.CLICK,recorddeal);
		stop_bt.addEventListener(MouseEvent.CLICK,stopdeal);
		//play_bt.addEventListener(MouseEvent.CLICK,playdeal);
		//save_bt.addEventListener(MouseEvent.CLICK,savedeal);
		
		stop_bt.visible=true;
		record_bt.visible=false;;
		this.record();

		

		}
		//录音时间的计算
		public function onTimerHandler(e:TimerEvent):void{
		timecount++;
		
		timeArea.text=getFormatTime(timecount);
		//trace(timecount);
		}
		//Mic声音指示
		public function onMicVoice(e:TimerEvent):void{
		
		if (microphone!=null)
		{
			setmicv(microphone.activityLevel);  
		}
		
		}
		//得到时分秒格式数据
		public function getFormatTime(timecountin:int ):String{
			
			
			var h= Math.floor(timecountin/(60*60));
       		 var m=Math.floor((timecountin/60) % 60);
        	var s=Math.floor((timecountin) % 60);
			var timeformat:String  = m.toString()+":"+s.toString();
			return timeformat;
			}
			
			
		public function setmicv(level:Number):void{
			if(level>0 && level<=25){
				mic_25.visible = true;
				mic_51.visible = false;
				mic_75.visible = false;
				mic_100.visible = false;
				
			}
			if(level>25 && level<=50){
				mic_25.visible = true;
				mic_51.visible = true;
				mic_75.visible = false;
				mic_100.visible = false;
				
			}
			if(level>50 && level<=75){
				mic_25.visible = true;
				mic_51.visible = true;
				mic_75.visible = true;
				mic_100.visible = false;
				
			}
			if(level>75 && level<=100){
				mic_25.visible = true;
				mic_51.visible = true;
				mic_75.visible = true;
				mic_100.visible = true;
				
			}
			 
			
			
		}
			
			
			
		//停止录音
		private function stopdeal(e:MouseEvent)
		{
			
			stop_bt.visible=false;;
			record_bt.visible=true;
			
			stop_bt.removeEventListener(MouseEvent.CLICK,stopdeal);
			record_bt.addEventListener(MouseEvent.CLICK,recorddeal);
			play_bt.addEventListener(MouseEvent.CLICK,playdeal);
			save_bt.addEventListener(MouseEvent.CLICK,savedeal);
		
			timer.removeEventListener(TimerEvent.TIMER,onTimerHandler);
		

			this.stop();

		}
		
		//播放录音
		private function playdeal(e:MouseEvent)
		{
			stop_bt.visible=true;
			record_bt.visible=false;;
			
			timecount = 0;
			play_bt.removeEventListener(MouseEvent.CLICK,playdeal);
			stop_bt.addEventListener(MouseEvent.CLICK,stopdeal);
			timer.start();
			timer.addEventListener(TimerEvent.TIMER,onTimerPlayHandler);
			this.playmp3();

		}


			public function onTimerPlayHandler(e:TimerEvent):void{
					timecount++;
					if(timecount<=(duration)){
					timeArea.text=getFormatTime(timecount)+"/"+getFormatTime(duration);
					}else
					//trace(timecount);
					{timer.removeEventListener(TimerEvent.TIMER,onTimerPlayHandler);
					play_bt.addEventListener(MouseEvent.CLICK,playdeal);
					}
				}
		
		
		//保存和上传
			private function savedeal(e:MouseEvent)
			{
				stop_bt.removeEventListener(MouseEvent.CLICK,stopdeal);
				record_bt.removeEventListener(MouseEvent.CLICK,recorddeal);
				play_bt.removeEventListener(MouseEvent.CLICK,playdeal);
				save_bt.removeEventListener(MouseEvent.CLICK,savedeal);
				// var _file = new FileReference();
				//_file.save(this._mp3encoder.mp3Data, "recorded.mp3");
				//
				//_file = new FileReference();
				//_file.save(_mp3encoder.mp3Data, "recorded.mp3");
				
				
				//uploadUrl = "http://localhost/upload/upload.php";
				
				JSupload(this.URLpost,this.FileName);

			}

			public function playmp3():void
			{
			
			mp3parser = new MP3Parser();
			mp3parser.loadFile(_mp3encoder.mp3Data);
			
			mp3parser.addEventListener(Event.COMPLETE, loadEnd);
			
			
			
			}
			
			//mp3加载完成处理函数
			public function loadEnd(e:Event)
			{
			
			sound = new Sound();
			sound = mp3parser.getSound();
			channel = sound.play();
			
			}
			
			
			//录音函数
			public function record():void
			{
			if (! microphone)
			{
				setupMicrophone();
			}
			
			microphoneWasMuted = microphone.muted;
			if (microphoneWasMuted)
			{
				 
			}
			else
			{
				notifyRecordingStarted();
			}
			
			buffer = new ByteArray();
			microphone.addEventListener(SampleDataEvent.SAMPLE_DATA, recordSampleDataHandler);
			}
			
			//暂停录音
			protected function pauseRecord():void{
				
				
				microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, recordSampleDataHandler);
				
				timer.removeEventListener(TimerEvent.TIMER,onTimerHandler);
				
				
				}
			protected function continueRecord():void{
				
				
				microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, recordSampleDataHandler);
				
				timer.removeEventListener(TimerEvent.TIMER,onTimerHandler);
				
				}
				

			//停止录音
			protected function recordStop():int
			{
			
			isRecording = false;
			//triggerEvent('recordingStop', {duration: recordingDuration()});
			microphone.removeEventListener(SampleDataEvent.SAMPLE_DATA, recordSampleDataHandler);
			microphone = null;
			 duration  = timecount;
			encoderStartTime = getTimer();
			
			_wavencoder = new WaveEncoder();
			
			wavbuffer = _wavencoder.encode(buffer,1,16,sampleRate * 1000);
			encoderArea.visible = true;
			_mp3encoder = new ShineMP3Encoder(wavbuffer,encoderArea);
			_mp3encoder.addEventListener(Event.COMPLETE, onEncoded);
			_mp3encoder.EncoderMP3();
			
			return duration;
			}

			//编码结束处理函数
			protected function onEncoded(e:Event):int
			{
			
			encoderArea.visible = false;
			//Security.showSettings(SecurityPanel.PRIVACY);
			encoderDurationTime = getTimer() - encoderStartTime;
			return encoderDurationTime;
			
			}


			//Stop 包括录音停止和播放停止
			public function stop():int
			{
			if (microphone)
			{
				return recordStop();
			}
			else
			{
			
				playStop();
				return 0;
			}
			
			}
			//播放停止
			protected function playStop():void
			{
			//logger.log('stopPlaying');
			if (channel)
			{
				channel.stop();
				//playingProgressTimer.reset();
			
				//triggerEvent('playingStop', {});
				isPlaying = false;
			}
			}
			
			
			
			//JSupload通过JS传递参数，进行调用
			//frm.attr('action').toString(),"upload_file[filename]", frm.serializeArray()，filename
			private function JSupload( URLpost:String,filename:String):void
			{
			
			
			
			var boundary:String = MultiPartFormUtil.boundary();
			
			//this.uploadFormData.push(MultiPartFormUtil.nameValuePair(data.name, data.value));
			//this.uploadFormData.push(MultiPartFormUtil.nameValuePair('upload_file[parent_id]', "1"));
			//this.uploadFormData.push(MultiPartFormUtil.nameValuePair("format", "json"));
			
			this.uploadFormData.push( MultiPartFormUtil.fileField('upload_file[filename]', _mp3encoder.mp3Data, filename, "audio/mpeg") );
			var request:URLRequest = MultiPartFormUtil.request(this.uploadFormData);
			this.uploadFormData.pop();
			
			request.url =URLpost;
			
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onSaveComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			loader.addEventListener(ProgressEvent.PROGRESS, onProgress);
			loader.load(request);
			}
			
			
			
			
			
			
			
			
			//调用别的库来实现upload
			
			private function _upload( filename:String):void
			{
			
			var boundary:String = MultiPartFormUtil.boundary();
			
			//this.uploadFormData.push(MultiPartFormUtil.nameValuePair(data.name, data.value));
			//this.uploadFormData.push(MultiPartFormUtil.nameValuePair('upload_file[parent_id]', "1"));
			//this.uploadFormData.push(MultiPartFormUtil.nameValuePair("format", "json"));
			
			this.uploadFormData.push( MultiPartFormUtil.fileField('upload_file[filename]', _mp3encoder.mp3Data, filename, "audio/mpeg") );
			var request:URLRequest = MultiPartFormUtil.request(this.uploadFormData);
			this.uploadFormData.pop();
			
			request.url = this.uploadUrl;
			
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onSaveComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onIOError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSecurityError);
			loader.addEventListener(ProgressEvent.PROGRESS, onProgress);
			loader.load(request);
			}
			
			//保存完毕处理函数
			private function onSaveComplete(event:Event):void
			{
			stop_bt.addEventListener(MouseEvent.CLICK,stopdeal);
			record_bt.addEventListener(MouseEvent.CLICK,recorddeal);
			play_bt.addEventListener(MouseEvent.CLICK,playdeal);
			save_bt.addEventListener(MouseEvent.CLICK,savedeal);
			
			
			}
			//出现问题处理函数
			private function onIOError(event:Event):void
			{
			}
			//安全问题处理函数
			private function onSecurityError(event:Event):void
			{
			}
			//正在进行处理函数
			private function onProgress(event:ProgressEvent):void
			{
				
			    
			 
			
			}
			
			
			
			

			/* 设置mic*/
			protected function setupMicrophone():void
			{
			microphone = Microphone.getMicrophone();
			microphone.codec = "Nellymoser";
			microphone.setSilenceLevel(0);
			microphone.rate = sampleRate;
			microphone.gain = 50;
			microphone.addEventListener(StatusEvent.STATUS, function statusHandler(e:Event) {
			if(microphone.muted){
			//triggerEvent('recordingCancel','');
			}else{
			if(!isRecording){
			notifyRecordingStarted();
			}
			}
			});
			
			}
			//开始录音处理函数
			protected function notifyRecordingStarted():void
			{
			if (microphoneWasMuted)
			{
				microphoneWasMuted = false;
				//triggerEvent('hideFlash','');
			}
			timer.start();
			timer.addEventListener(TimerEvent.TIMER,onTimerHandler);
			timermic.start();
			timermic.addEventListener(TimerEvent.TIMER,onMicVoice);
			//triggerEvent('recordingStart', {});
			isRecording = true;
			}
			
			
			//播放时间点
			protected function playDuration():int
			{
			return int(channel.position);
			}
			
			
			//录音处理函数
			protected function recordSampleDataHandler(event:SampleDataEvent):void
			{
			while (event.data.bytesAvailable)
			{
				var sample:Number = event.data.readFloat();
			
				buffer.writeFloat(sample);
				if (buffer.length % 40000 == 0)
				{
					//triggerEvent('recordingProgress', recordingDuration(), microphone.activityLevel);
				}
			}
			}
			
			}
			}