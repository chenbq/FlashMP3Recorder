﻿/*
Copyright (c) 2008 Christopher Martin-Sperry (audiofx.org@gmail.com)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

package com.adobe.audio.mp3
{
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.system.ApplicationDomain;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	import flash.media.Sound;

	import flash.text.TextField;
	
	//[Event(name="complete", type="flash.events.Event")]
	public class MP3Parser extends EventDispatcher
	{
		public var mp3Data:ByteArray;
		private var loader:URLLoader;
		private var currentPosition:uint;
		private var sampleRate:uint;
		private var channels:uint;
		private var version:uint;
		private static var bitRates:Array=[-1,32,40,48,56,64,80,96,112,128,160,192,224,256,320,-1,-1,8,16,24,32,40,48,56,64,80,96,112,128,144,160,-1];
		private static var versions:Array=[2.5,-1,2,1];
		private static var samplingRates:Array = [44100, 48000, 32000];
		private static var objSound:Sound;
		
		public function get CurrentPosition():uint
		{
			return currentPosition;
		}
		
		public function MP3Parser()
		{
			
			loader=new URLLoader();
			loader.dataFormat=URLLoaderDataFormat.BINARY;
			loader.addEventListener(Event.COMPLETE,loaderCompleteHandler);
			loader.addEventListener(ProgressEvent.PROGRESS,loaderProgressHandler);
		}
		
		public function load(url:String):void
		{
			var req:URLRequest=new URLRequest(url);
			loader.load(req);
		}
		internal function loadFileRef(fileRef:FileReference):void
		{
			fileRef.addEventListener(Event.COMPLETE,loaderCompleteHandler);
			fileRef.addEventListener(IOErrorEvent.IO_ERROR,errorHandler);
			//fileRef.addEventListener(Event.COMPLETE,loaderCompleteHandler);
			//fileRef.load();
		}
		public function loadFile(bytes:ByteArray):void
		{
			mp3Data=bytes;
			currentPosition=getFirstHeaderPosition();
			generateSound();
		}
		public function getSound():Sound
		{
			return objSound;
		}  
		public function generateSound():Boolean
		{
				var swfBytes:ByteArray=new ByteArray();
				swfBytes.endian=Endian.LITTLE_ENDIAN;
				for(var i:uint=0;i<SoundClassSwfByteCode.soundClassSwfBytes1.length;++i)
				{
						swfBytes.writeByte(SoundClassSwfByteCode.soundClassSwfBytes1[i]);
				}
				var swfSizePosition:uint=swfBytes.position;
				swfBytes.writeInt(0); //swf size will go here
				for(i=0;i<SoundClassSwfByteCode.soundClassSwfBytes2.length;++i)
				{
						swfBytes.writeByte(SoundClassSwfByteCode.soundClassSwfBytes2[i]);
				}
				var audioSizePosition:uint=swfBytes.position;
				swfBytes.writeInt(0); //audiodatasize+7 to go here
				swfBytes.writeByte(1);
				swfBytes.writeByte(0);
				writeSwfFormatByte(swfBytes);
			   
				var sampleSizePosition:uint=swfBytes.position;
				swfBytes.writeInt(0); //number of samples goes here
			   
				swfBytes.writeByte(0); //seeksamples
				swfBytes.writeByte(0);
									   
				var frameCount:uint=0;
			   
				var byteCount:uint=0; //this includes the seeksamples written earlier
									   
				for(;;)
				{
			   
						var seg:ByteArraySegment=getNextFrame();
						if(seg==null)break;
						swfBytes.writeBytes(seg.byteArray,seg.start,seg.length);
						byteCount+=seg.length;
						frameCount++;
				}
				if(byteCount==0)
				{
						return false;
				}
				byteCount+=2;

				var currentPos:uint=swfBytes.position;
				swfBytes.position=audioSizePosition;
				swfBytes.writeInt(byteCount+7);
				swfBytes.position=sampleSizePosition;
				swfBytes.writeInt(frameCount*1152);
				swfBytes.position=currentPos;
				for(i=0;i<SoundClassSwfByteCode.soundClassSwfBytes3.length;++i)
				{
						swfBytes.writeByte(SoundClassSwfByteCode.soundClassSwfBytes3[i]);
				}
				swfBytes.position=swfSizePosition;
				swfBytes.writeInt(swfBytes.length);
				swfBytes.position=0;
				var swfBytesLoader:Loader =new Loader();
				var loaderContext:LoaderContext = new LoaderContext();
				//loaderContext.allowLoadBytesCodeExecution = true;
				swfBytesLoader.contentLoaderInfo.addEventListener(Event.COMPLETE,swfCreated);
				swfBytesLoader.loadBytes(swfBytes,loaderContext);
				return true;
		}
		private function swfCreated(ev:Event):void
		{
				var loaderInfo:LoaderInfo=ev.currentTarget as LoaderInfo;
				var soundClass:Class=loaderInfo.applicationDomain.getDefinition("SoundClass") as Class;
				var sound:Sound=new soundClass();
				objSound=sound;                       
				dispatchEvent(ev);             
		}
		private function errorHandler(ev:IOErrorEvent):void
		{
			trace("error\n"+ev.text);
		}
		
		public function get MP3DATA():ByteArray
		{
			return mp3Data;
		}
		
		private function loaderProgressHandler(ev:ProgressEvent):void
		{
			mp3Data = ev.currentTarget.data as ByteArray;
			dispatchEvent(ev);
		}
		
		private function loaderCompleteHandler(ev:Event):void
		{
			mp3Data = ev.currentTarget.data as ByteArray;
			try
			{
				currentPosition = getFirstHeaderPosition();
			}
			catch (e:Error)
			{
				dispatchEvent(new ErrorEvent(MP3SoundEvent.INVALID_STREAM))
				return;
			}
			dispatchEvent(ev);
		}
		private function getFirstHeaderPosition():uint
		{
			mp3Data.position = 0;
			
			while(mp3Data.position<mp3Data.length)
			{
				var readPosition:uint=mp3Data.position;
				var str:String=mp3Data.readMultiByte(3,"us-ascii");
				
				
				if(str=="ID3") //here's an id3v2 header. fuck that for a laugh. skipping
				{
					mp3Data.position+=3;
					var b3:int=(mp3Data.readByte()&0x7F)<<21;
					var b2:int=(mp3Data.readByte()&0x7F)<<14;
					var b1:int=(mp3Data.readByte()&0x7F)<<7;
					var b0:int=mp3Data.readByte()&0x7F;
					var headerLength:int=b0+b1+b2+b3;
					var newPosition:int=mp3Data.position+headerLength;
					trace("Found id3v2 header, length "+headerLength.toString(16)+" bytes. Moving to "+newPosition.toString(16));
					mp3Data.position=newPosition;
					readPosition=newPosition;
				}
				else
				{
					mp3Data.position=readPosition;
				}
				
				var val:uint=mp3Data.readInt();
				
				if(isValidHeader(val))
				{
					parseHeader(val);
					mp3Data.position=readPosition+getFrameSize(val);
					if(isValidHeader(mp3Data.readInt()))
					{
						return readPosition;
					}
					trace('fsdfas');
				}
			}
			throw(new Error("Could not locate first header. This isn't an MP3 file"));
		}
		public function getNextFrame():*
		{
			mp3Data.position=currentPosition;
			var headerByte:uint;
			var frameSize:uint;	
			while(true)
			{
				if(currentPosition>(mp3Data.length-4))
				{
					trace("passed eof");
					return null;
				}
				headerByte=mp3Data.readInt();
				if(isValidHeader(headerByte))
				{
					frameSize=getFrameSize(headerByte);
					if(frameSize!=0xffffffff)
					{
						break;
					}
				}
				currentPosition=mp3Data.position;
				
			}

			mp3Data.position=currentPosition;
			
			if((currentPosition+frameSize)>mp3Data.length)
			{
				return null;
			}
			
			currentPosition+=frameSize;
			return new ByteArraySegment(mp3Data,mp3Data.position,frameSize);
		}
		public function writeSwfFormatByte(byteArray:ByteArray):void
		{
			var sampleRateIndex:uint=4-(44100/sampleRate);
			byteArray.writeByte((2<<4)+(sampleRateIndex<<2)+(1<<1)+(channels-1));
		}
		private function parseHeader(headerBytes:uint):void
		{
			var channelMode:uint=getModeIndex(headerBytes);
			version=getVersionIndex(headerBytes);
			var samplingRate:uint=getFrequencyIndex(headerBytes);
			channels=(channelMode>2)?1:2;
			var actualVersion:Number=versions[version];
			var samplingRates:Array=[44100,48000,32000];
			sampleRate=samplingRates[samplingRate];
			switch(actualVersion)
			{
				case 2:
					sampleRate/=2;
					break;
				case 2.5:
					sampleRate/=4;
			}
			
		}
		private function getFrameSize(headerBytes:uint):uint
		{
			
			
			var version:uint=getVersionIndex(headerBytes);
			var bitRate:uint=getBitrateIndex(headerBytes);
			var samplingRate:uint=getFrequencyIndex(headerBytes);
			var padding:uint=getPaddingBit(headerBytes);
			var channelMode:uint=getModeIndex(headerBytes);
			var actualVersion:Number=versions[version];
			var sampleRate:uint=samplingRates[samplingRate];
			if(sampleRate!=this.sampleRate||this.version!=version)
			{
				return 0xffffffff;
			}
			switch(actualVersion)
			{
				case 2:
					sampleRate/=2;
					break;
				case 2.5:
					sampleRate/=4;
			}
			var bitRatesYIndex:uint=((actualVersion==1)?0:1)*bitRates.length/2;
			var actualBitRate:uint=bitRates[bitRatesYIndex+bitRate]*1000;			
			var frameLength:uint=(((actualVersion==1?144:72)*actualBitRate)/sampleRate)+padding;
			return frameLength;
			
		}
		
	 	private function isValidHeader(headerBits:uint):Boolean 
	    {
	        return (((getFrameSync(headerBits)      & 2047)==2047) &&
	                ((getVersionIndex(headerBits)   &    3)!=   1) &&
	                ((getLayerIndex(headerBits)     &    3)!=   0) && 
	                ((getBitrateIndex(headerBits)   &   15)!=   0) &&
	                ((getBitrateIndex(headerBits)   &   15)!=  15) &&
	                ((getFrequencyIndex(headerBits) &    3)!=   3) &&
	                ((getEmphasisIndex(headerBits)  &    3)!=   2)    );
	    }
	
	    private function getFrameSync(headerBits:uint):uint     
	    {
	        return uint((headerBits>>21) & 2047); 
	    }
	
	    private function getVersionIndex(headerBits:uint):uint  
	    { 
	        return uint((headerBits>>19) & 3);  
	    }
	
	    private function getLayerIndex(headerBits:uint):uint    
	    { 
	        return uint((headerBits>>17) & 3);  
	    }
	
	    private function getBitrateIndex(headerBits:uint):uint  
	    { 
	        return uint((headerBits>>12) & 15); 
	    }
	
	    private function getFrequencyIndex(headerBits:uint):uint
	    { 
	        return uint((headerBits>>10) & 3);  
	    }
	
	    private function getPaddingBit(headerBits:uint):uint    
	    { 
	        return uint((headerBits>>9) & 1);  
	    }
	
	    private function getModeIndex(headerBits:uint):uint     
	    { 
	        return uint((headerBits>>6) & 3);  
	    }
	
	    private function getEmphasisIndex(headerBits:uint):uint
	    { 
	        return uint(headerBits & 3);  
	    }
		
	}
}