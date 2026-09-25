"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { useAuth } from "@/lib/auth";
import { api } from "@/lib/api";

interface TriageEntry {
  user_id: string;
  service_id: string;
  full_name: string;
  unit: string;
  risk_level: string;
  resilience_score: number;
  contributing_factors: string;
  recommended_intervention: string;
  assessment_id: string;
  status: string;
  created_at: string;
}

const riskConfig: Record<string, { label: string; class: string; priority: number }> = {
  Intervention_Recommended: {
    label: "Needs Support",
    class: "risk-badge-intervention",
    priority: 1,
  },
  Monitor: {
    label: "Monitor",
    class: "risk-badge-monitor",
    priority: 2,
  },
  Routine: {
    label: "Routine",
    class: "risk-badge-routine",
    priority: 3,
  },
};

const statusConfig: Record<string, { label: string; variant: "default" | "secondary" | "outline" }> = {
  Pending: { label: "Pending", variant: "outline" },
  Acknowledged: { label: "Acknowledged", variant: "secondary" },
  Action_Taken: { label: "Action Taken", variant: "default" },
};

export default function TriagePage() {
  const { role } = useAuth();
  const [entries, setEntries] = useState<TriageEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<string>("all");
  const router = useRouter();

  // Recommend to CO modal state
  const [recommendModal, setRecommendModal] = useState<{
    open: boolean;
    entry: TriageEntry | null;
  }>({ open: false, entry: null });
  const [recommendNote, setRecommendNote] = useState("");
  const [recommendSubmitting, setRecommendSubmitting] = useState(false);
  const [recommendSuccess, setRecommendSuccess] = useState<string | null>(null);
  const [recommendError, setRecommendError] = useState<string | null>(null);

  useEffect(() => {
    if (role === "Commander") {
      router.push("/overview");
    } else {
      loadTriage();
    }
  }, [role, router]);

  const loadTriage = async () => {
    try {
      const data = await api.getTriage();
      // Sort by risk priority
      data.sort((a: TriageEntry, b: TriageEntry) => {
        const pa = riskConfig[a.risk_level]?.priority ?? 9;
        const pb = riskConfig[b.risk_level]?.priority ?? 9;
        return pa - pb;
      });
      setEntries(data);
    } catch (err) {
      console.error("Failed to load triage:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleAction = async (assessmentId: string, status: string) => {
    try {
      await api.takeAction(assessmentId, status);
      await loadTriage();
    } catch (err) {
      console.error("Action failed:", err);
    }
  };

  const openRecommendModal = (entry: TriageEntry) => {
    setRecommendModal({ open: true, entry });
    setRecommendNote("");
    setRecommendSuccess(null);
    setRecommendError(null);
  };

  const closeRecommendModal = () => {
    setRecommendModal({ open: false, entry: null });
    setRecommendNote("");
    setRecommendError(null);
  };

  const handleRecommendSubmit = async () => {
    if (!recommendModal.entry || !recommendNote.trim()) return;
    setRecommendSubmitting(true);
    setRecommendError(null);
    try {
      await api.createRecommendation({
        soldier_id: recommendModal.entry.user_id,
        assessment_id: recommendModal.entry.assessment_id,
        note: recommendNote.trim(),
      });
      setRecommendSuccess(recommendModal.entry.full_name);
      setTimeout(() => {
        closeRecommendModal();
        setRecommendSuccess(null);
      }, 2000);
    } catch (err: any) {
      console.error("Recommendation failed:", err);
      setRecommendError(
        err?.message && err.message !== "Unauthorized"
          ? err.message
          : "Failed to send recommendation. Please try again."
      );
    } finally {
      setRecommendSubmitting(false);
    }
  };

  const filtered = filter === "all"
    ? entries
    : entries.filter((e) => e.risk_level === filter);

  if (loading || role === "Commander") {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin h-8 w-8 border-2 border-primary border-t-transparent rounded-full" />
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fade-in">
      <div>
        <h1 className="text-2xl font-bold tracking-tight">Welfare Triage Grid</h1>
        <p className="text-muted-foreground text-[13px] mt-1.5 leading-relaxed">
          Personnel requiring welfare attention, ordered by priority
        </p>
      </div>

      {/* Success banner */}
      {recommendSuccess && (
        <div className="flex items-center gap-3 px-4 py-3 rounded-xl border bg-emerald-500/10 border-emerald-500/30 text-emerald-400 text-[13px] animate-fade-in">
          <span className="text-base">✅</span>
          <span className="font-medium">
            Recommendation for {recommendSuccess} sent to Commanding Officer successfully.
          </span>
          <button
            onClick={() => setRecommendSuccess(null)}
            className="ml-auto text-current opacity-60 hover:opacity-100 transition-opacity cursor-pointer"
          >
            ✕
          </button>
        </div>
      )}

      {/* Filters */}
      <div className="flex gap-2 flex-wrap">
        {[
          { key: "all", label: "All", count: entries.length },
          { key: "Intervention_Recommended", label: "Needs Support", count: entries.filter((e) => e.risk_level === "Intervention_Recommended").length },
          { key: "Monitor", label: "Monitor", count: entries.filter((e) => e.risk_level === "Monitor").length },
          { key: "Routine", label: "Routine", count: entries.filter((e) => e.risk_level === "Routine").length },
        ].map((f) => (
          <button
            key={f.key}
            onClick={() => setFilter(f.key)}
            className={`px-3.5 py-2 rounded-lg text-[13px] font-medium transition-all cursor-pointer ${
              filter === f.key
                ? "bg-primary text-primary-foreground"
                : "bg-muted text-muted-foreground hover:bg-accent"
            }`}
          >
            {f.label} ({f.count})
          </button>
        ))}
      </div>

      {/* Triage Cards */}
      {filtered.length === 0 ? (
        <Card className="glass-card">
          <CardContent className="py-12 text-center">
            <p className="text-muted-foreground">No assessments found. Run an AI assessment from the Overview page.</p>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-4">
          {filtered.map((entry, i) => {
            const risk = riskConfig[entry.risk_level] || riskConfig.Routine;
            const status = statusConfig[entry.status] || statusConfig.Pending;
            const showRecommend = entry.risk_level !== "Routine";
            return (
              <Card
                key={entry.assessment_id}
                className="glass-card hover:bg-accent/30 transition-colors animate-slide-up cursor-pointer"
                style={{ animationDelay: `${i * 0.05}s` }}
                onClick={() => router.push(`/personnel/${entry.user_id}`)}
              >
                <CardContent className="py-4">
                  <div className="flex flex-col lg:flex-row lg:items-center gap-4">
                    {/* Personnel info */}
                    <div className="flex items-center gap-3 lg:w-56 shrink-0">
                      <div className={`w-10 h-10 rounded-full flex items-center justify-center text-sm font-bold border ${risk.class}`}>
                        {entry.full_name.charAt(0)}
                      </div>
                      <div>
                        <p className="font-medium text-[13px]">{entry.full_name}</p>
                        <p className="text-[12px] text-muted-foreground mt-0.5">{entry.service_id} • {entry.unit}</p>
                      </div>
                    </div>

                    {/* Risk badge */}
                    <div className="lg:w-36 shrink-0">
                      <span className={`inline-flex items-center px-2.5 py-1 rounded-full text-[12px] font-semibold border ${risk.class}`}>
                        {risk.label}
                      </span>
                    </div>

                    {/* Factors & Recommendation */}
                    <div className="flex-1 min-w-0 space-y-1.5">
                      <p className="text-[13px] text-muted-foreground leading-relaxed">
                        <span className="font-medium text-foreground/90">Factors:</span> {entry.contributing_factors}
                      </p>
                      <p className="text-[13px] text-muted-foreground leading-relaxed">
                        <span className="font-medium text-foreground/90">Recommended:</span> {entry.recommended_intervention}
                      </p>
                    </div>

                    {/* Status & Actions */}
                    <div className="flex items-center gap-2 shrink-0 flex-wrap" onClick={(e) => e.stopPropagation()}>
                      <Badge variant={status.variant} className="text-[11px]">
                        {status.label}
                      </Badge>
                      {entry.status === "Pending" && (
                        <button
                          onClick={() => handleAction(entry.assessment_id, "Acknowledged")}
                          className="px-3.5 py-1.5 rounded-md bg-primary/10 text-primary text-[12px] font-medium hover:bg-primary/20 transition-colors cursor-pointer"
                        >
                          Acknowledge
                        </button>
                      )}
                      {entry.status === "Acknowledged" && (
                        <button
                          onClick={() => handleAction(entry.assessment_id, "Action_Taken")}
                          className="px-3.5 py-1.5 rounded-md bg-risk-routine/10 text-risk-routine text-[12px] font-medium hover:bg-risk-routine/20 transition-colors cursor-pointer"
                        >
                          Mark Done
                        </button>
                      )}
                      {showRecommend && (
                        <button
                          onClick={() => openRecommendModal(entry)}
                          className="px-3.5 py-1.5 rounded-md bg-amber-500/10 text-amber-400 text-[12px] font-medium hover:bg-amber-500/20 transition-colors cursor-pointer flex items-center gap-1.5"
                        >
                          <svg className="w-3.5 h-3.5" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                            <path strokeLinecap="round" strokeLinejoin="round" d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 0 1 .865-.501 48.172 48.172 0 0 0 3.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0 0 12 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018Z" />
                          </svg>
                          Recommend to CO
                        </button>
                      )}
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}

      {/* Recommend to CO Modal */}
      {recommendModal.open && recommendModal.entry && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center">
          {/* Backdrop */}
          <div
            className="absolute inset-0 bg-black/60 backdrop-blur-sm"
            onClick={closeRecommendModal}
          />

          {/* Modal */}
          <div className="relative w-full max-w-lg mx-4 bg-card border border-border rounded-2xl shadow-2xl animate-fade-in overflow-hidden">
            {/* Header */}
            <div className="px-6 py-5 border-b border-border">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-amber-500/15 border border-amber-500/25 flex items-center justify-center">
                  <svg className="w-5 h-5 text-amber-400" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                    <path strokeLinecap="round" strokeLinejoin="round" d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 0 1 .865-.501 48.172 48.172 0 0 0 3.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0 0 12 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018Z" />
                  </svg>
                </div>
                <div>
                  <h3 className="text-[15px] font-semibold">Recommend to Commanding Officer</h3>
                  <p className="text-[12px] text-muted-foreground mt-0.5">
                    Escalate this soldier for CO attention
                  </p>
                </div>
              </div>
            </div>

            {/* Body */}
            <div className="px-6 py-5 space-y-5">
              {/* Soldier info */}
              <div className="flex items-center gap-3 p-3.5 rounded-xl bg-muted/50 border border-border/50">
                <div className={`w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold border ${riskConfig[recommendModal.entry.risk_level]?.class || "risk-badge-routine"}`}>
                  {recommendModal.entry.full_name.charAt(0)}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-[13px]">{recommendModal.entry.full_name}</p>
                  <p className="text-[12px] text-muted-foreground">{recommendModal.entry.service_id} • {recommendModal.entry.unit}</p>
                </div>
                <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[11px] font-semibold border ${riskConfig[recommendModal.entry.risk_level]?.class || "risk-badge-routine"}`}>
                  {riskConfig[recommendModal.entry.risk_level]?.label || "Unknown"}
                </span>
              </div>

              {/* Note input */}
              <div>
                <label htmlFor="recommend-note" className="block text-[13px] font-medium mb-2">
                  Note for Commanding Officer <span className="text-muted-foreground">(required)</span>
                </label>
                <textarea
                  id="recommend-note"
                  value={recommendNote}
                  onChange={(e) => setRecommendNote(e.target.value)}
                  placeholder="Describe why this soldier needs the CO's attention — e.g. observed behavioral changes, risk factors, recommended actions..."
                  className="w-full h-32 px-4 py-3 rounded-xl bg-background border border-border text-[13px] placeholder:text-muted-foreground/60 resize-none focus:outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary/50 transition-all"
                />
                <p className="text-[11px] text-muted-foreground mt-1.5">
                  This note will be visible to the Commanding Officer along with the soldier&apos;s risk assessment.
                </p>
              </div>
            </div>

            {/* Error message */}
            {recommendError && (
              <div className="mx-6 mb-0 px-4 py-3 rounded-xl bg-destructive/10 border border-destructive/25 text-[12px] text-destructive flex items-center gap-2">
                <span>⚠️</span>
                <span>{recommendError}</span>
              </div>
            )}

            {/* Footer */}
            <div className="px-6 py-4 border-t border-border flex items-center justify-end gap-3">
              <button
                onClick={closeRecommendModal}
                className="px-4 py-2 rounded-lg text-[13px] font-medium text-muted-foreground hover:text-foreground hover:bg-accent transition-colors cursor-pointer"
              >
                Cancel
              </button>
              <button
                onClick={handleRecommendSubmit}
                disabled={!recommendNote.trim() || recommendSubmitting}
                className="px-5 py-2 rounded-lg bg-amber-500 text-white text-[13px] font-medium hover:bg-amber-500/90 transition-colors disabled:opacity-50 cursor-pointer flex items-center gap-2"
              >
                {recommendSubmitting ? (
                  <>
                    <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                    </svg>
                    Sending...
                  </>
                ) : (
                  <>
                    <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                      <path strokeLinecap="round" strokeLinejoin="round" d="M6 12 3.269 3.125A59.769 59.769 0 0 1 21.485 12 59.768 59.768 0 0 1 3.27 20.875L5.999 12Zm0 0h7.5" />
                    </svg>
                    Send Recommendation
                  </>
                )}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
