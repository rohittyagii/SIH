const API_URL = "/api/proxy";

function getToken(): string | null {
  if (typeof window === "undefined") return null;
  return localStorage.getItem("welfare_token");
}

export async function apiFetch<T>(
  path: string,
  options: RequestInit = {}
): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = {
    "Content-Type": "application/json",
    ...(options.headers as Record<string, string>),
  };

  if (token) {
    headers["Authorization"] = `Bearer ${token}`;
  }

  let res;
  try {
    res = await fetch(`${API_URL}${path}`, {
      ...options,
      headers,
    });
  } catch (err: any) {
    console.warn("Network or CORS error in fetch:", err.message);
    throw err;
  }

  if (res.status === 401) {
    if (typeof window !== "undefined") {
      localStorage.removeItem("welfare_token");
      localStorage.removeItem("welfare_user");
      window.location.href = "/";
    }
    throw new Error("Unauthorized");
  }

  if (!res.ok) {
    const err = await res.json().catch(() => ({ detail: "Request failed" }));
    throw new Error(err.detail || `API Error: ${res.status}`);
  }

  return res.json();
}

// Typed API helpers
export const api = {
  // Auth
  getProfile: () => apiFetch<any>("/auth/me"),

  // Personnel
  listPersonnel: (unit?: string) =>
    apiFetch<any[]>(unit ? `/personnel?unit=${encodeURIComponent(unit)}` : "/personnel"),
  getPersonnelDetail: (id: string) => apiFetch<any>(`/personnel/${id}`),

  // HR Metrics
  getUnitSummary: () => apiFetch<any[]>("/hr-metrics/unit-summary"),

  // Wellness
  submitCheckin: (data: any) =>
    apiFetch<any>("/wellness/checkin", { method: "POST", body: JSON.stringify(data) }),
  getMyHistory: (limit = 30) => apiFetch<any[]>(`/wellness/history?limit=${limit}`),

  // Assessments
  runAssessment: (personnelId: string) =>
    apiFetch<any>(`/assessments/run/${personnelId}`, { method: "POST" }),
  runUnitAssessment: (unit?: string) =>
    apiFetch<any[]>(`/assessments/run-unit${unit ? `?unit=${encodeURIComponent(unit)}` : ""}`, {
      method: "POST",
    }),
  getTriage: () => apiFetch<any[]>("/assessments/triage"),
  getTrends: () => apiFetch<any[]>("/assessments/trends"),
  getAssessmentHistory: (personnelId: string) =>
    apiFetch<any[]>(`/assessments/history/${personnelId}`),
  takeAction: (assessmentId: string, status: string) =>
    apiFetch<any>(`/assessments/${assessmentId}/action`, {
      method: "PATCH",
      body: JSON.stringify({ status }),
    }),
};
