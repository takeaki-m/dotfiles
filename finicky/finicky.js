export default {
    defaultBrowser: "Zen",
    options: {
      // hide the finicky icon from the menu bar
      hideIcon: true
    },
    handlers: [
        {
            match: () => {
                const d = new Date();
                const day = d.getDay(); // 0=日,6=土
                const hour = d.getHours();
                const isWeekday = day >= 1 && day <= 5;
                const inBizHours = hour >= 6 && hour < 20;
                return isWeekday && inBizHours;
            },
            browser: "Google Chrome"
        },
        { match: () => true, browser: "Zen" }
    ]
};
