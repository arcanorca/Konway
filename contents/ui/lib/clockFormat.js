.pragma library

// Clock text for the wallpaper overlay. The AM/PM marker is returned separately
// so it can be drawn as a smaller suffix next to the digits.
function formatClock(date, options) {
    const o = options || {};
    const hours = date.getHours();
    const mm = String(date.getMinutes()).padStart(2, "0");

    if (!o.hour12) {
        return { text: String(hours).padStart(2, "0") + ":" + mm, suffix: "" };
    }

    const h12 = hours % 12 === 0 ? 12 : hours % 12;
    const hh = o.leadingZero ? String(h12).padStart(2, "0") : String(h12);
    return {
        text: hh + ":" + mm,
        suffix: o.showAmPm ? (hours < 12 ? "AM" : "PM") : ""
    };
}
