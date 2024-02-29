// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

const colors = require("tailwindcss/colors");

module.exports = {
  content: ["./js/**/*.js", "../lib/*_web.ex", "../lib/*_web/**/*.*ex"],
  theme: {
    extend: {
      colors: {
        white: colors.white,
        green: colors.emerald,
        purple: colors.indigo,
        yellow: colors.amber,
        gray: {
          50: "#f8f9fc",
          100: "#f1f2f9",
          200: "#e1e2ef",
          300: "#cbcee1",
          400: "#9497b8",
          500: "#65688b",
          600: "#484b6a",
          700: "#343756",
          800: "#1d1e3a",
          900: "#100f29",
          950: "#050217",
        },
      },
    },
  },
  plugins: [require("@tailwindcss/forms")],
};
