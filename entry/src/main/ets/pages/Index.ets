import { webview } from '@kit.ArkWeb'
import { BuilderNode, curves, NodeController } from '@kit.ArkUI'
import { windowsUtil } from '../utils/WindowsUtil'
import { cookieStore } from '../utils/CookieStore'

interface WebsiteData{
  icon: Resource
  url: string
}

@Builder
function WebBuilder(url: string) {
    Web({ src: url, controller: new webview.WebviewController })
      .width("100%")
      .height("100%")
      .keyboardAvoidMode(WebKeyboardAvoidMode.RESIZE_VISUAL)
      .javaScriptAccess(true)
      .cacheMode(CacheMode.Default)
      .allowWindowOpenMethod(true)
      .domStorageAccess(true)
      .databaseAccess(true)
      .fileAccess(true)
      .zoomAccess(false)
      .horizontalScrollBarAccess(false)
      .verticalScrollBarAccess(false)
      .mixedMode(MixedMode.All)
      .darkMode(WebDarkMode.Off)
      .backgroundColor('#f5f2ea')
}

let wrap = wrapBuilder<string[]>(WebBuilder);

export class WebNodeController extends NodeController {
  private node: BuilderNode<string[]> | null = null;

  makeNode(_uiContext: UIContext): FrameNode | null {
    if (this.node != null) {
      return this.node.getFrameNode();
    }
    return null;
  }

  initWeb(url: string, context: UIContext) {
    if (this.node != null) {
      return;
    }
    this.node = new BuilderNode(context);
    this.node.build(wrap, url);
  }
}

let nodeMap: Map<string, WebNodeController> = new Map();

export const createNode = (url: string, context: UIContext) => {
  let node = new WebNodeController();
  node.initWeb(url, context);
  nodeMap.set(url, node);
}

export const getWebView = (url: string, context: UIContext): WebNodeController | undefined => {
  if(nodeMap.has(url)){
    return nodeMap.get(url)
  }else{
    createNode(url, context)
    return nodeMap.get(url)
  }
}

@Entry
@ComponentV2
struct Index {
  @Local url: string | undefined
  isMoving: boolean = false
  websiteList: WebsiteData[] = [
    {
      icon: $r('app.media.genshin'),
      url: 'https://ys.mihoyo.com/cloud/#/'
    },
    {
      icon: $r('app.media.starrail'),
      url: 'https://sr.mihoyo.com/cloud/#/'
    }
  ]

  onBackPress(): boolean | void {
    if(this.url){
      // Cookie 保活：退出网页前把当前登录态备份到沙箱（含 session cookie）
      cookieStore.saveAll()
      this.getUIContext().animateTo({ curve: curves.springMotion(0.6, 0.8) }, () => {
        this.url = undefined
      })
      windowsUtil.setKeepScreenOn(false)
      return true
    }
    return false
  }

  build() {
    Stack() {
      // 背景层：syncLoad 同步解码，保证首帧与图标一起出现，不出现“图标先、背景后”的闪烁
      Image($r('app.media.wallpaper'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
        .interpolation(ImageInterpolation.High)
        .syncLoad(true)
        .draggable(false)

      RelativeContainer() {
        Row({ space: 10 }) {
          ForEach(this.websiteList, (website: WebsiteData) => {
            Button({ type: ButtonType.Normal, stateEffect: true }) {
              Image(website.icon)
                .width('100%')
                .height('100%')
                .syncLoad(true)
                .draggable(false)
            }
            .backgroundColor(Color.Transparent)
            .borderRadius('10%')
            .height('55%')
            .clip(true)
            .aspectRatio(1)
            .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.95 })
            .geometryTransition(website.url, { follow: true })
            .transition(TransitionEffect.OPACITY)
            .onClick(() => {
              windowsUtil.setKeepScreenOn(true)
              this.getUIContext().animateTo({ curve: curves.springMotion(0.4, 1) }, () => this.url = website.url)
            })
          })
        }
        .height('100%')
        .width('100%')
        .alignItems(VerticalAlign.Center)
        .justifyContent(FlexAlign.SpaceAround)
        .translate({z: this.url? 100: 0})
        .alignRules({
          center: { anchor: "__container__", align: VerticalAlign.Center },
          middle: { anchor: "__container__", align: HorizontalAlign.Center }
        })

        Stack()
          .brightness(this.url? 0.75: 1)
          .height('100%')
          .width('100%')
          .blur(this.url? 50: 0)
          .enabled(false)
          .alignRules({
            center: { anchor: "__container__", align: VerticalAlign.Center },
            middle: { anchor: "__container__", align: HorizontalAlign.Center }
          })

        if (this.url) {
          NodeContainer(getWebView(this.url, this.getUIContext()))
            .geometryTransition(this.url, { follow: true })
            .transition(TransitionEffect.OPACITY)
            .alignRules({
              center: { anchor: "__container__", align: VerticalAlign.Center },
              middle: { anchor: "__container__", align: HorizontalAlign.Center }
            })
        }

        Stack()
          .width('100%')
          .height(70)
          .alignRules({
            top: { anchor: "__container__", align: VerticalAlign.Top },
            middle: { anchor: "__container__", align: HorizontalAlign.Center }
          })
          .hitTestBehavior(HitTestMode.Transparent)
          .onTouch((event)=>{
            if(event.type == TouchType.Move){
              windowsUtil.moveWindow(true)
              this.isMoving = true
            }else{
              if(this.isMoving){
                windowsUtil.moveWindow(false)
              }
              this.isMoving = false
            }

          })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.start_window_background'))
  }
}