import { backgroundTaskManager } from '@kit.BackgroundTasksKit'
import { common, wantAgent, WantAgent } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'BackgroundKeep'

/**
 * 长时任务保活（计算任务 TASK_KEEPING）：
 * 进入云游戏网页时申请长时任务，通知栏显示"正在进行计算任务"，
 * 应用切后台后进程不会被冻结/回收，游戏不中断。
 * 离开游戏网页时停止长时任务并移除通知。
 *
 * 权限：ohos.permission.KEEP_BACKGROUND_RUNNING（module.json5 已声明）。
 * TASK_KEEPING 类型在 PC / 二合一设备上可用；手机上若无系统级 ACL 权限会申请失败，
 * 失败时静默降级为系统默认的后台音频保活行为，不影响正常使用。
 */
class BackgroundKeep {
  private context?: common.Context
  private active: boolean = false

  init(context: common.Context): void {
    this.context = context
  }

  /** 申请长时任务（计算任务）。进入游戏网页时调用。 */
  async start(): Promise<void> {
    if (this.active || !this.context) {
      return
    }
    try {
      // 通知点击后回到应用
      const wantAgentObj: WantAgent = await wantAgent.getWantAgent({
        wants: [{
          bundleName: 'com.nrc.huawei',
          abilityName: 'EntryAbility'
        }],
        operationType: wantAgent.OperationType.START_ABILITY,
        requestCode: 0
      })
      await backgroundTaskManager.startBackgroundRunning(this.context, ['taskKeeping'], wantAgentObj)
      this.active = true
      hilog.info(DOMAIN, TAG, 'continuous task (taskKeeping) started')
    } catch (err) {
      // 常见失败：设备类型不支持 TASK_KEEPING / 缺少 ACL 权限（9500005、9800005 等）
      hilog.error(DOMAIN, TAG, 'startBackgroundRunning failed: %{public}s', JSON.stringify(err))
    }
  }

  /** 停止长时任务并移除通知栏"正在进行计算任务"。离开游戏网页时调用。 */
  async stop(): Promise<void> {
    if (!this.active || !this.context) {
      return
    }
    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context)
      hilog.info(DOMAIN, TAG, 'continuous task stopped')
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'stopBackgroundRunning failed: %{public}s', JSON.stringify(err))
    }
    this.active = false
  }

  isRunning(): boolean {
    return this.active
  }
}

export const backgroundKeep = new BackgroundKeep()
