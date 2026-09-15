import Component from "@glimmer/component";

/**
 * Stands in for a theme screenshot: a sketch of a blog page painted with the
 * theme's own palette, so designs are told apart at a glance.
 */
export default class BlogThemeThumbnail extends Component {
  get paper() {
    return this.#paint(this.args.theme.paper_color, "var(--secondary)");
  }

  get ink() {
    return this.#paint(this.args.theme.ink_color, "var(--primary)");
  }

  get accent() {
    return this.#paint(this.args.theme.accent_color, "var(--tertiary)");
  }

  #paint(value, fallback) {
    return /^[0-9a-f]{6}$/i.test(value) ? `#${value}` : fallback;
  }

  <template>
    <svg
      class="blog-theme-thumbnail"
      viewBox="0 0 320 160"
      width="100%"
      height="100%"
      preserveAspectRatio="xMidYMid slice"
      role="img"
      aria-label={{@label}}
    >
      <rect width="320" height="160" fill={{this.paper}} />

      <rect
        y="34"
        width="320"
        height="1"
        fill={{this.ink}}
        fill-opacity="0.15"
      />
      <rect
        x="16"
        y="13"
        width="58"
        height="9"
        rx="2"
        fill={{this.ink}}
        fill-opacity="0.85"
      />
      <rect
        x="222"
        y="15"
        width="26"
        height="5"
        rx="2.5"
        fill={{this.ink}}
        fill-opacity="0.35"
      />
      <rect
        x="254"
        y="15"
        width="26"
        height="5"
        rx="2.5"
        fill={{this.ink}}
        fill-opacity="0.35"
      />
      <rect
        x="286"
        y="15"
        width="18"
        height="5"
        rx="2.5"
        fill={{this.accent}}
      />

      <rect
        x="16"
        y="52"
        width="176"
        height="13"
        rx="3"
        fill={{this.ink}}
        fill-opacity="0.8"
      />
      <rect
        x="16"
        y="72"
        width="120"
        height="7"
        rx="3.5"
        fill={{this.ink}}
        fill-opacity="0.3"
      />
      <rect x="16" y="86" width="34" height="7" rx="3.5" fill={{this.accent}} />

      <rect
        x="16"
        y="108"
        width="140"
        height="38"
        rx="4"
        fill={{this.ink}}
        fill-opacity="0.06"
      />
      <rect
        x="26"
        y="118"
        width="18"
        height="18"
        rx="3"
        fill={{this.accent}}
        fill-opacity="0.85"
      />
      <rect
        x="52"
        y="119"
        width="86"
        height="6"
        rx="3"
        fill={{this.ink}}
        fill-opacity="0.55"
      />
      <rect
        x="52"
        y="132"
        width="60"
        height="5"
        rx="2.5"
        fill={{this.ink}}
        fill-opacity="0.25"
      />

      <rect
        x="164"
        y="108"
        width="140"
        height="38"
        rx="4"
        fill={{this.ink}}
        fill-opacity="0.06"
      />
      <rect
        x="174"
        y="118"
        width="18"
        height="18"
        rx="3"
        fill={{this.accent}}
        fill-opacity="0.5"
      />
      <rect
        x="200"
        y="119"
        width="86"
        height="6"
        rx="3"
        fill={{this.ink}}
        fill-opacity="0.55"
      />
      <rect
        x="200"
        y="132"
        width="60"
        height="5"
        rx="2.5"
        fill={{this.ink}}
        fill-opacity="0.25"
      />
    </svg>
  </template>
}
