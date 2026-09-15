const comments = document.getElementById("discourse-comments");

if (comments) {
  const loadDiscussion = () => {
    const discussion = comments.closest(".blog-discussion");
    discussion.classList.add("is-loading");
    const failure = discussion.querySelector(".blog-discussion__load-error");
    const failDiscussion = () => {
      discussion.classList.remove("is-loading");
      discussion.classList.add("is-failed");
      failure.hidden = false;
      window.removeEventListener("message", handleDiscussionMessage);
      clearTimeout(timeout);
    };
    const discussOrigin = new URL(comments.dataset.discourseUrl).origin;
    // The embed cannot read the reader palette, so send it the colours it needs.
    const sendPalette = () => {
      const styles = getComputedStyle(document.documentElement);
      const frame = document.getElementById("discourse-embed-frame");
      frame?.contentWindow?.postMessage(
        {
          type: "discourse-blog-palette",
          accent: styles.getPropertyValue("--blog-accent-color").trim(),
          paper: styles.getPropertyValue("--blog-paper-color").trim(),
          ink: styles.getPropertyValue("--blog-ink-color").trim(),
        },
        discussOrigin
      );
    };
    const timeout = setTimeout(failDiscussion, 30000);
    const handleDiscussionMessage = (event) => {
      const frame = document.getElementById("discourse-embed-frame");
      if (
        event.origin !== discussOrigin ||
        event.source !== frame?.contentWindow
      ) {
        return;
      }
      if (event.data?.type === "discourse-blog-resize") {
        const height = event.data.height;
        if (
          typeof height === "number" &&
          Number.isFinite(height) &&
          height > 0
        ) {
          // Leave a pixel for fractional layout rounding at non-default zoom levels.
          frame.style.height = `${Math.max(280, Math.ceil(height) + 1)}px`;
          frame.scrolling = "auto";
        }
      } else if (event.data?.type === "discourse-blog-ready") {
        clearTimeout(timeout);
        discussion.classList.remove("is-loading");
        sendPalette();
      }
    };
    window.addEventListener("message", handleDiscussionMessage);

    window.DiscourseEmbed = {
      discourseUrl: comments.dataset.discourseUrl,
      topicId: Number(comments.dataset.topicId),
      fullApp: true,
      className: "discourse-blog-discussion",
      embedHeight: "320px",
      dynamicHeight: false,
      embedMinHeight: 280,
      lazyLoad: false,
      discourseReferrerPolicy: "strict-origin-when-cross-origin",
    };
    const script = document.createElement("script");
    script.src = `${comments.dataset.discourseUrl}javascripts/embed.js`;
    script.onerror = failDiscussion;
    script.onload = () => {
      const frame = document.getElementById("discourse-embed-frame");
      if (frame) {
        frame.title = comments.dataset.title;
        frame.scrolling = "auto";
      }
    };
    document.head.appendChild(script);
  };

  const observer = new IntersectionObserver(
    (entries) => {
      if (entries.some((entry) => entry.isIntersecting)) {
        observer.disconnect();
        loadDiscussion();
      }
    },
    { rootMargin: "300px" }
  );
  observer.observe(comments);
}
