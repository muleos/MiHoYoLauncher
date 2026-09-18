import { window } from '@kit.ArkUI'

const TRANSPARENT_COLOR: string = '#00000000'
const SOLID_BACKGROUND_COLOR: string = '#161a29'

@ObservedV2
export class WindowsUtil {
  windowClass?: window.Window
  @Trace decorBarButtonPadding: number = 0

  init(windowStage: window.WindowStage) {
    try {
      this.windowClass = windowStage.getMainWindowSync()
      this.windowClass.setWindowLayoutFullScreen(true)
      windowStage.setWindowRectAutoSave(true, true);
      this.windowClass.on("windowStatusChange", (status) => {
        if (status == window.WindowStatusType.MAXIMIZE) {
          this.windowClass?.maximize(window.MaximizePresentation.ENTER_IMMERSIVE)
        }
      });
    } catch {
    }
  }

  // 启动阶段：窗口背景与启动页保持一致（透明），避免出现任何遮罩层
  prepareTransparentWindow(windowStage: window.WindowStage) {
    try {
      const mainWindow = windowStage.getMainWindowSync()
      mainWindow.setWindowBackgroundColor(TRANSPARENT_COLOR)
    } catch {
    }
  }

  // 首帧绘制完成后：立即恢复为应用底色，避免桌面长时间透出
  restoreWindowBackground(windowStage: window.WindowStage) {
    try {
      const mainWindow = windowStage.getMainWindowSync()
      mainWindow.setWindowBackgroundColor(SOLID_BACKGROUND_COLOR)
    } catch {
    }
  }


  async moveWindow(isMoving: boolean) {
    if (this.windowClass) {
      try {
        if (isMoving) {
          await this.windowClass.startMoving()
        } else {
          await this.windowClass.stopMoving()
        }
      } catch {
      }
    }
  }

  async setKeepScreenOn(isOn: boolean) {
    try {
      if (this.windowClass) {
        await this.windowClass.setWindowKeepScreenOn(isOn)
      }
    } catch {
    }
  }
}

export const windowsUtil = new WindowsUtil()