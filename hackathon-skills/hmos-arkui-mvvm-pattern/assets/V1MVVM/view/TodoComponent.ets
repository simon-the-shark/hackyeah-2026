@Component
export struct TodoComponent {
  build() {
    Row() {
      Text('All Todos')
        .fontSize(30)
        .fontWeight(FontWeight.Bold)
    }
    .padding({ left: 15 })
    .width('50%')
    .margin({ top: 10, bottom: 10 })
  }
}
