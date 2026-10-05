import { webview } from '@kit.ArkWeb'
import { preferences } from '@kit.ArkData'
import { common } from '@kit.AbilityKit'
import { hilog } from '@kit.PerformanceAnalysisKit'

const DOMAIN = 0x0000
const TAG = 'CookieStore'
const PREF_NAME = 'web_cookie_backup'
const KEY_PREFIX = 'cookie_'

/**
 * 需要备份登录态的 URL 列表。
 * fetchCookieSync 按 URL 匹配所属域，登录态可能分散在主站 / 登录 / 云游戏 API 各子域，需逐个列出。
 * 列表可以只多不少：无 Cookie 的域 fetch 会抛 17100002，已被 saveAll 捕获忽略。
 */
const COOKIE_URLS: string[] = [
  'https://mihoyo.com/',
  'https://user.mihoyo.com/',
  'https://ys.mihoyo.com/',
  'https://sr.mihoyo.com/',
  'https://api-takumi.mihoyo.com/',
  'https://api-sdk.mihoyo.com/',
  'https://hk4e-sdk.mihoyo.com/',
  'https://api-cloudgame.mihoyo.com/',
  'https://cg-hk4e-api.mihoyo.com/',
  'https://bbs-sdk.mihoyo.com/'
]

/**
 * Cookie 保活：
 * 鸿蒙 ArkWeb 在 PC / 二合一 / 平板设备上不会把 session cookie（无过期时间）持久化到磁盘，
 * 应用进程退出后这类 Cookie 即丢失，导致云游戏页面频繁掉登录。
 * 本模块在退出网页 / 应用切后台时，把内存中的完整 Cookie（含 session cookie）备份到应用沙箱；
 * 下次启动时在任何 Web 创建之前写回引擎，实现“只要不主动退出登录，登录态一直保留”。
 */
class CookieStore {
  private store?: preferences.Preferences

  init(context: common.Context): void {
    try {
      this.store = preferences.getPreferencesSync(context, { name: PREF_NAME })
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'init failed: %{public}s', JSON.stringify(err));
    }
  }

  /** 备份当前内存 Cookie（含 session cookie）到磁盘。在离开网页 / 应用切后台时调用。 */
  saveAll(): void {
    if (!this.store) {
      return
    }
    let saved = 0
    for (const url of COOKIE_URLS) {
      try {
        const cookie: string = webview.WebCookieManager.fetchCookieSync(url)
        if (cookie && cookie.length > 0) {
          this.store.putSync(KEY_PREFIX + url, cookie)
          saved++
        }
      } catch {
        // 17100002：该 URL 下没有 Cookie，属正常情况，忽略
      }
    }
    try {
      this.store.flushSync()
    } catch (err) {
      hilog.error(DOMAIN, TAG, 'flush failed: %{public}s', JSON.stringify(err));
    }
    try {
      // 顺带把有过期时间的 Cookie 强制落盘，双保险
      webview.WebCookieManager.saveCookieSync()
    } catch {
    }
    hilog.info(DOMAIN, TAG, 'saved cookies for %{public}d domains', saved)
  }

  /** 启动时把备份的 Cookie 写回引擎（含无过期时间的 session cookie）。必须在任何 Web 创建之前调用。 */
  restoreAll(): void {
    if (!this.store) {
      return
    }
    let restored = 0
    for (const url of COOKIE_URLS) {
      try {
        const cookie: string = this.store.getSync(KEY_PREFIX + url, '') as string
        if (cookie && cookie.length > 0) {
          // includeHttpOnly=true：还原时允许写回 HttpOnly 标记的 Cookie
          webview.WebCookieManager.configCookieSync(url, cookie, false, true)
          restored++
        }
      } catch (err) {
        hilog.error(DOMAIN, TAG, 'restore %{public}s failed: %{public}s', url, JSON.stringify(err));
      }
    }
    hilog.info(DOMAIN, TAG, 'restored cookies for %{public}d domains', restored)
  }

  /** 清空备份（预留：若页面内主动退出登录，下次备份会自然覆盖为未登录态，一般无需调用） */
  clearAll(): void {
    if (!this.store) {
      return
    }
    try {
      this.store.clearSync()
      this.store.flushSync()
    } catch {
    }
  }
}

export const cookieStore = new CookieStore()
