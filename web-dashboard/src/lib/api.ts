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
  /** Run real ML assessments for every active soldier across all units at once. */
  runAllAssessments: () =>
    apiFetch<{ total: number; assessed: number; skipped: number; errors: number; results: any[] }>(
      "/assessments/run-all",
      { method: "POST" }
    ),
  getTriage: () => apiFetch<any[]>("/assessments/triage"),
  getTrends: () => apiFetch<any[]>("/assessments/trends"),
  getAssessmentHistory: (personnelId: string) =>
    apiFetch<any[]>(`/assessments/history/${personnelId}`),
  takeAction: (assessmentId: string, status: string) =>
    apiFetch<any>(`/assessments/${assessmentId}/action`, {
      method: "PATCH",
      body: JSON.stringify({ status }),
    }),

  // Disclosures
  createDisclosure: (data: { subject_user_id: string; justification_category: string; justification_text: string }) =>
    apiFetch<any>("/disclosures/", { method: "POST", body: JSON.stringify(data) }),
  initiateDisclosure: (id: string) =>
    apiFetch<any>(`/disclosures/${id}/initiate`, { method: "POST" }),
  approveDisclosure: (id: string) =>
    apiFetch<any>(`/disclosures/${id}/approve`, { method: "POST" }),
  denyDisclosure: (id: string) =>
    apiFetch<any>(`/disclosures/${id}/deny`, { method: "POST" }),
  getDisclosedData: (id: string) =>
    apiFetch<any>(`/disclosures/${id}/data`),
  listDisclosures: (status?: string) =>
    apiFetch<any[]>(`/disclosures/${status ? `?status=${status}` : ""}`),

  // Notifications
  getNotifications: () =>
    apiFetch<any[]>("/notifications/"),
  getUnreadCount: () =>
    apiFetch<{ count: number }>("/notifications/unread-count"),
  markNotificationRead: (id: string) =>
    apiFetch<any>(`/notifications/${id}/read`, { method: "PATCH" }),
  markAllNotificationsRead: () =>
    apiFetch<any>("/notifications/read-all", { method: "PATCH" }),

  // Recommendations
  createRecommendation: (data: { soldier_id: string; assessment_id?: string; note: string }) =>
    apiFetch<any>("/recommendations/", { method: "POST", body: JSON.stringify(data) }),
  getOutgoingRecommendations: () =>
    apiFetch<any[]>("/recommendations/outgoing"),
  getIncomingRecommendations: () =>
    apiFetch<any[]>("/recommendations/incoming"),
  updateRecommendation: (id: string, data: { status: string; commander_response?: string }) =>
    apiFetch<any>(`/recommendations/${id}`, { method: "PATCH", body: JSON.stringify(data) }),
};
