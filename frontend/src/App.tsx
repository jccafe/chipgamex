import React, { useEffect, useState } from "react";

type HealthResponse = { status: string };

export default function App() {
  const [status, setStatus] = useState<string>("loading...");

  useEffect(() => {
    fetch("http://localhost:8000/api/v1/health")
      .then((r) => r.json() as Promise<HealthResponse>)
      .then((d) => setStatus(d.status))
      .catch(() => setStatus("api_error"));
  }, []);

  return (
    <main style={{ fontFamily: "sans-serif", padding: "24px" }}>
      <h1>ChipGameX MVP</h1>
      <p>API health: {status}</p>
    </main>
  );
}
