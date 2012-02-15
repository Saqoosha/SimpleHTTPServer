package sh.saqoo.SimpleHTTPServer {

	import org.osflash.signals.Signal;

	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.events.Event;
	import flash.events.NativeProcessExitEvent;
	import flash.events.ProgressEvent;
	import flash.filesystem.File;
	import flash.utils.IDataInput;


	/**
	 * @author Saqoosha
	 */
	public class Server {
		
		
		private var _documentRoot:String;
		private var _port:int;
		public function get port():int { return _port; }
		private var _address:String;
		public function get address():String { return _address; }
		public function get url():String { return 'http://' + (_address ? _address : 'localhost') + ':' + _port + '/'; }
		private var _proc:NativeProcess;
		
		private var _log:Signal = new Signal(String);
		public function get log():Signal { return _log; }
		private var _exited:Signal = new Signal(Number);
		public function get exited():Signal { return _exited; }


		public function Server(documentRoot:String, port:int = 0, address:String = '') {
			_documentRoot = documentRoot;
			_port = port;
			_address = address;
		}
		
		
		public function start():void {
			if (_proc) stop();
			
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			info.workingDirectory = File.applicationDirectory;
			info.executable = new File('/usr/bin/env');
			info.arguments = new <String>['bash', 'serv', _documentRoot];
			if (_port) info.arguments.push(_port);
			if (_address) info.arguments.push(_address);
			_proc = new NativeProcess();
			_proc.addEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, _onOutputData);
			_proc.addEventListener(ProgressEvent.STANDARD_ERROR_DATA, _onErrorData);
			_proc.addEventListener(NativeProcessExitEvent.EXIT, _onExit);
			_proc.start(info);
		}
		
		
		public function stop():void {
			if (!_proc) return;
			
			_proc.exit(true);
			_proc.removeEventListener(ProgressEvent.STANDARD_OUTPUT_DATA, _onOutputData);
			_proc.removeEventListener(ProgressEvent.STANDARD_ERROR_DATA, _onErrorData);
			_proc.removeEventListener(NativeProcessExitEvent.EXIT, _onExit);
			_proc = null;
		}
		
		
		private function _onOutputData(e:Event):void {
			_out(_proc.standardOutput);
		}
		
		
		private function _onErrorData(e:Event):void {
			_out(_proc.standardError);
		}
		
		
		private function _out(input:IDataInput):void {
			var text:String = input.readUTFBytes(input.bytesAvailable);
			_log.dispatch(text.replace(/[\r\n]+/g, '\n'));
		}
		
		
		private function _onExit(e:NativeProcessExitEvent):void {
			trace(e);
			_exited.dispatch(e.exitCode);
		}
	}
}
