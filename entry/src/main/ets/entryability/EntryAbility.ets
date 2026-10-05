import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { webview } from '@kit.ArkWeb';
import { windowsUtil } from '../utils/WindowsUtil';
import { cookieStore } from '../utils/CookieStore';
import { backgroundKeep } from '../utils/BackgroundKeep';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    // 提前初始化 Web 引擎：Cookie 备份/还原依赖引擎，且可加快首次 WebView 打开速度
    try {
      webview.WebviewController.initializeWebEngine()
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'initializeWebEngine failed: %{public}s', JSON.stringify(err));
    }
    // Cookie 保活：初始化备份存储（应用沙箱 preferences）
    cookieStore.init(this.context.getApplicationContext());
    // 长时任务保活：初始化上下文（进入游戏网页时申请"计算任务"长时任务）
    backgroundKeep.init(this.context.getApplicationContext());
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 窗口背景透明：与透明启动页保持连续，冷启动全程不出现遮罩层
    windowsUtil.prepareTransparentWindow(windowStage);

    windowStage.loadContent('pages/Index', async (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        windowsUtil.restoreWindowBackground(windowStage);
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
      // Cookie 保活：在任何 Web 创建之前，把上次备份的登录 Cookie 写回引擎（含 session cookie）
      cookieStore.restoreAll();
      windowsUtil.init(windowStage)
      // 首帧已直出，恢复应用底色
      windowsUtil.restoreWindowBackground(windowStage);
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
    // Cookie 保活：切后台时备份内存中的完整 Cookie（含 session cookie），防止进程回收后丢失
    cookieStore.saveAll();
  }
}