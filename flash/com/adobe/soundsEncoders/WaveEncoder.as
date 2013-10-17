package com.adobe.soundsEncoders
{
	import flash.events.Event;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	public class WaveEncoder
	{
		 public function encode( samples:ByteArray, channels:int=2, bits:int=16, rate:int=44100 ):ByteArray
		{
			var data:ByteArray = this.create( samples );
			
			var bytes: ByteArray = new ByteArray();
			bytes.endian = Endian.LITTLE_ENDIAN;
			
			bytes.writeUTFBytes( 'RIFF' );
			bytes.writeInt( uint( data.length + 44 ) );
			bytes.writeUTFBytes( 'WAVE' );
			bytes.writeUTFBytes( 'fmt ' );
			bytes.writeInt( uint( 16 ) );
			bytes.writeShort( uint( 1 ) );
			bytes.writeShort( channels );
			bytes.writeInt( rate );
			bytes.writeInt( uint( rate * channels * ( bits / 8 ) ) );
			bytes.writeShort( uint( channels * ( bits / 8 ) ) );
			bytes.writeShort( bits );
			bytes.writeUTFBytes( 'data' );
			bytes.writeInt( data.length );
			bytes.writeBytes( data );
			bytes.position = 0;
			return bytes;
		}
		
		 public function create( bytes:ByteArray ):ByteArray
		{
			var buffer:ByteArray = new ByteArray();
			buffer.endian = Endian.LITTLE_ENDIAN;
			bytes.position = 0;
			
			while( bytes.bytesAvailable ) 
				buffer.writeShort( bytes.readFloat() * 0x7fff );
			return buffer;
		}
	}
}