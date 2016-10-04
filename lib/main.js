const {Disposable, CompositeDisposable} = require('atom')
const ViewURI = 'atom://deprecation-cop'
let DeprecationCopView

class DeprecationCopPackage {
  activate () {
    this.disposables = new CompositeDisposable()
    this.disposables.add(atom.workspace.addOpener((uri) => {
      if (uri === ViewURI) {
        return this.deserializeDeprecationCopView({uri})
      }
    }))
    this.disposables.add(atom.commands.add('atom-workspace', 'deprecation-cop:view', () => {
      atom.workspace.open(ViewURI)
    }))
  }

  deactivate () {
    this.disposables.dispose()
    const pane = atom.workspace.paneForURI(ViewURI)
    if (pane) {
      pane.destroyItem(pane.itemForURI(ViewURI))
    }
  }

  deserializeDeprecationCopView (state) {
    if (!DeprecationCopView) {
      DeprecationCopView = require('./deprecation-cop-view')
    }
    return new DeprecationCopView(state)
  }

  consumeStatusBar (statusBar) {
    const DeprecationCopStatusBarView = require('./deprecation-cop-status-bar-view')
    const statusBarView = new DeprecationCopStatusBarView()
    const statusBarTile = statusBar.addRightTile({item: statusBarView, priority: 150})
    this.disposables.add(new Disposable(() => { statusBarView.destroy() }))
    this.disposables.add(new Disposable(() => { statusBarTile.destroy() }))
  }
}

module.exports = new DeprecationCopPackage()
