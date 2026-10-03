import {
  Attention,
  attentionLabel,
  RatingTone,
  ratingLabel,
  ratingOf,
  ratingTone,
  REPORT_TOPICS,
  ReportTopic,
  reportSourceLabel,
  topicTitle,
  WellbeingReport
} from '../models/Wellbeing';

function toneAccent(tone: RatingTone): Resource {
  if (tone === RatingTone.Good) {
    return $r('app.color.success');
  }
  if (tone === RatingTone.Concern) {
    return $r('app.color.warning');
  }
  return tone === RatingTone.Neutral ? $r('app.color.guardian_accent') : $r('app.color.text_secondary');
}

function toneTint(tone: RatingTone): Resource {
  if (tone === RatingTone.Good) {
    return $r('app.color.success_tint');
  }
  if (tone === RatingTone.Concern) {
    return $r('app.color.warning_tint');
  }
  return tone === RatingTone.Neutral ? $r('app.color.guardian_tint') : $r('app.color.page_background');
}

export function attentionAccent(attention: Attention): Resource {
  return attention === Attention.Urgent ? $r('app.color.sos') : $r('app.color.warning');
}

export function attentionTint(attention: Attention): Resource {
  return attention === Attention.Urgent ? $r('app.color.sos_tint') : $r('app.color.warning_tint');
}

/** Small "Please read soon" pill; renders nothing for a report that needs no attention. */
@Component
export struct AttentionPill {
  @Prop attention: Attention = Attention.None;

  build() {
    if (this.attention !== Attention.None) {
      Row({ space: 6 }) {
        SymbolGlyph($r('sys.symbol.exclamationmark_circle_fill'))
          .fontSize(16)
          .fontColor([attentionAccent(this.attention)])
        Text(attentionLabel(this.attention))
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
      }
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .borderRadius(14)
      .backgroundColor(attentionTint(this.attention))
      .accessibilityGroup(true)
    }
  }
}

/**
 * The shared part of a check-in report: the summary, mood/energy/sleep/pain in words and the
 * things the senior mentioned. Used where the senior sees what was sent and where the guardian reads it.
 */
@Component
export struct WellbeingReportView {
  @Prop report: WellbeingReport = new WellbeingReport();

  @Builder
  rating(topic: ReportTopic) {
    Column({ space: 4 }) {
      Text(topicTitle(topic))
        .fontSize(15)
        .fontColor($r('app.color.text_secondary'))
      Text(ratingLabel(topic, ratingOf(this.report, topic)))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(toneAccent(ratingTone(topic, ratingOf(this.report, topic))))
    }
    .layoutWeight(1)
    .padding(12)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(16)
    .backgroundColor(toneTint(ratingTone(topic, ratingOf(this.report, topic))))
    .accessibilityGroup(true)
    .accessibilityText(`${topicTitle(topic)}: ${ratingLabel(topic, ratingOf(this.report, topic))}`)
  }

  build() {
    Column({ space: 16 }) {
      if (this.report.summary !== '') {
        Text(this.report.summary)
          .fontSize(19)
          .lineHeight(28)
          .fontColor($r('app.color.text_primary'))
          .width('100%')
      }

      if (!this.report.summaryUnavailable) {
        Column({ space: 10 }) {
          Row({ space: 10 }) {
            this.rating(REPORT_TOPICS[0])
            this.rating(REPORT_TOPICS[1])
          }
          .width('100%')
          Row({ space: 10 }) {
            this.rating(REPORT_TOPICS[2])
            this.rating(REPORT_TOPICS[3])
          }
          .width('100%')
        }
        .width('100%')
      }

      if (this.report.concerns.length > 0) {
        Column({ space: 8 }) {
          Text('Mentioned')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_secondary'))
          ForEach(this.report.concerns, (concern: string) => {
            Row({ space: 10 }) {
              Text('•')
                .fontSize(18)
                .fontColor($r('app.color.text_secondary'))
              Text(concern)
                .fontSize(17)
                .fontColor($r('app.color.text_primary'))
                .layoutWeight(1)
            }
            .width('100%')
            .alignItems(VerticalAlign.Top)
          }, (concern: string, index: number) => `${index}:${concern}`)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }

      if (this.report.attention !== Attention.None && this.report.attentionReason !== '') {
        Row({ space: 10 }) {
          SymbolGlyph($r('sys.symbol.exclamationmark_circle_fill'))
            .fontSize(20)
            .fontColor([attentionAccent(this.report.attention)])
          Text(this.report.attentionReason)
            .fontSize(17)
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
        .padding(12)
        .borderRadius(14)
        .backgroundColor(attentionTint(this.report.attention))
        .accessibilityGroup(true)
      }

      Text(`${reportSourceLabel(this.report)}. It can be wrong and is not a medical assessment.`)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
}
