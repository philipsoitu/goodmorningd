Bun.serve({
  hostname: "0.0.0.0",
  port: Number(process.env.PORT ?? 42069),

  async fetch() {
    console.log("goodmorningd activated");

    const proc = Bun.spawn({
      cmd: [
        "codex",
        "exec",
        "--yolo",
        "--skip-git-repo-check",
        "Good morning",
      ],
      stdout: "pipe",
      stderr: "pipe",
    });

    const stdout = await new Response(proc.stdout).text();
    const stderr = await new Response(proc.stderr).text();

    console.log(stdout);
    if (stderr.trim()) console.error(stderr);

    return Response.json({
      ok: true,
      codex: stdout.trim(),
    });
  },
});

console.log("listening on port 42069");
