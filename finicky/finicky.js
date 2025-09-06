export default {
    defaultBrowser: "Zen",
    handlers: [
        {
            match: () => {
                const d = new Date();
                const day = d.getDay(); // 0=日,6=土
                const hour = d.getHours();
                const isWeekday = day >= 1 && day <= 5;
                const inBizHours = hour >= 9 && hour < 18;
                return isWeekday && inBizHours;
            },
            browser: "Google Chrome"
        },
        { match: () => true, browser: "Zen" }
    ]
};
