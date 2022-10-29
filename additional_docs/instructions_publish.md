# Publishing a new version

1. Ensure the version number in the following files is correct

- `README.md`
- `mix.exs`
- `package.json`

2. Ensure conversion between current and new version works
3. Run `npm run build` to update the prebuilt .js and declared type
4. Commit
5. Create new tag on Github
6. Run `mix hex.publish`
7. Run `npm publish`
