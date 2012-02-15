package sh.saqoo.SimpleHTTPServer {

	import flash.utils.setTimeout;
	import com.bit101.components.PushButton;
	import com.bit101.components.TextArea;
	import com.bit101.components.VBox;

	import flash.desktop.ClipboardFormats;
	import flash.desktop.NativeApplication;
	import flash.desktop.NativeDragManager;
	import flash.desktop.NativeProcess;
	import flash.desktop.NativeProcessStartupInfo;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageScaleMode;
	import flash.events.Event;
	import flash.events.NativeDragEvent;
	import flash.filesystem.File;


	public class SimpleHTTPServer extends Sprite {
		
		
		private var _list:VBox;
		private var _openButton:PushButton;
		private var _buttons:Vector.<PushButton> = new Vector.<PushButton>();
		private var _log:TextArea;
		private var _servers:Vector.<Server> = new Vector.<Server>();


		public function SimpleHTTPServer() {
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			_list = new VBox(this, 10, 10);
			_openButton = new PushButton(_list, 0, 0, 'DROP FOLDER HERE', _onClickOpen);
			_openButton.height = 100;
			_openButton.addEventListener(NativeDragEvent.NATIVE_DRAG_ENTER, _onDragEnter);
			_openButton.addEventListener(NativeDragEvent.NATIVE_DRAG_DROP, _onDragDrop);
			_log = new TextArea(_list);
			_log.editable = false;
			
			NativeApplication.nativeApplication.addEventListener(Event.EXITING, _onAppExiting);
			
			stage.addEventListener(Event.RESIZE, _onResize);
		}
		
		
		private function _onClickOpen(e:Event):void {
			var file:File = new File();
			file.browseForDirectory('Select Folder for Document Root');
			file.addEventListener(Event.SELECT, function(e:Event):void {
				_add(file);
			});
		}
		
		
		private function _onDragEnter(e:NativeDragEvent):void {
			if (e.clipboard.hasFormat(ClipboardFormats.FILE_LIST_FORMAT)) {
				NativeDragManager.acceptDragDrop(_openButton);
			}
		}
		
		
		private function _onDragDrop(e:NativeDragEvent):void {
			_add(e.clipboard.getData(ClipboardFormats.FILE_LIST_FORMAT)[0]);
		}
		
		
		private function _add(file:File):void {
			if (!file.isDirectory) file = file.resolvePath('../');
			var port:int = 10000 + _servers.length;
			var server:Server = new Server(file.nativePath, port);
			server.log.add(_onLog);
			server.exited.add(trace);
			server.start();
			setTimeout(_openURL, 500, server.url);
			_servers.push(server);
			_buttons.push(new PushButton(_list, 0, 0, file.nativePath + ' => ' + server.url, _onClickButton));
			_list.addChild(_log);
			_onResize(null);
		}
		
		
		private function _onLog(log:String):void {
			_log.text += log;
			_log.textField.scrollV = _log.textField.maxScrollV + 1;
		}
		
		
		private function _onClickButton(e:Event):void {
			var index:int = _buttons.indexOf(e.target);
			_openURL(_servers[index].url);
		}
		
		
		private function _onResize(e:Event):void {
			var w:int = stage.stageWidth - 20;
			_openButton.width = w;
			for each (var button:PushButton in _buttons) {
				button.width = w;
			}
			_log.width = w;
			_log.height = stage.stageHeight - _log.y - 20;
		}


		private function _onAppExiting(e:Event):void {
			trace(e);
			for each (var server:Server in _servers) {
				server.stop();
			}
		}
		
		
		private function _openURL(url:String):void {
			var info:NativeProcessStartupInfo = new NativeProcessStartupInfo();
			info.executable = new File('/usr/bin/env');
			info.arguments = new <String>['open', url];
			var proc:NativeProcess = new NativeProcess();
			proc.start(info);
		}
	}
}
