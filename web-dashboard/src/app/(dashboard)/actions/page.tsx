"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@/lib/auth";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { api } from "@/lib/api";

interface TriageEntry {
  personnel_id: number;
  service_id: string;
  full_name: string;
  unit: string;
  risk_level: string;
  contributing_factors: string;
  recommended_intervention: string;
  assessment_id: string;
  status: string;
  created_at: string;
}

interface Recommendation {
  id: string;
  welfare_officer_name: string;
  commander_name: string;
  soldier_id: string;
  soldier_name: string;
  soldier_service_id: string;
  unit_name: string;
  note: string;
  risk_level: string;
  status: string;
  commander_response: string | null;
  created_at: string;
  reviewed_at: string | null;
}

const riskConfig: Record<string, { label: string; class: string }> = {
  Intervention_Recommended: { label: "Needs Support", class: "risk-badge-intervention" },
  Monitor: { label: "Monitor", class: "risk-badge-monitor" },
  Routine: { label: "Routine", class: "risk-badge-routine" },
};

const recStatusConfig: Record<string, { label: string; color: string; bgColor: string }> = {
  Pending: { label: "Pending", color: "text-amber-400", bgColor: "bg-amber-500/10 border-amber-500/30" },
  Reviewed: { label: "Reviewed", color: "text-sky-400", bgColor: "bg-sky-500/10 border-sky-500/30" },
  Actioned: { label: "Actioned", color: "text-emerald-400", bgColor: "bg-emerald-500/10 border-emerald-500/30" },
};

const ACTION_CARDS = [
  {
    title: "Approve Pending Leave",
    description: "Fast-track leave approvals for personnel flagged with leave deficit stress factors.",
    icon: (
      <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" d="M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5m-9-6h.008v.008H12v-.008ZM12 15h.008v.008H12V15Zm0 2.25h.008v.008H12v-.008ZM9.75 15h.008v.008H9.75V15Zm0 2.25h.008v.008H9.75v-.008ZM7.5 15h.008v.008H7.5V15Zm0 2.25h.008v.008H7.5v-.008Zm6.75-4.5h.008v.008h-.008v-.008Zm0 2.25h.008v.008h-.008V15Zm0 2.25h.008v.008h-.008v-.008Zm2.25-4.5h.008v.008H16.5v-.008Zm0 2.25h.008v.008H16.5V15Z" />
      </svg>
    ),
    color: "text-chart-2",
    bgColor: "bg-chart-2/10",
  },
  {
    title: "Schedule Peer Counseling",
    description: "Arrange confidential peer support sessions for personnel with low mood indicators.",
    icon: (
      <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" d="M20.25 8.511c.884.284 1.5 1.128 1.5 2.097v4.286c0 1.136-.847 2.1-1.98 2.193-.34.027-.68.052-1.02.072v3.091l-3-3c-1.354 0-2.694-.055-4.02-.163a2.115 2.115 0 0 1-.825-.242m9.345-8.334a2.126 2.126 0 0 0-.476-.095 48.64 48.64 0 0 0-8.048 0c-1.131.094-1.976 1.057-1.976 2.192v4.286c0 .837.46 1.58 1.155 1.951m9.345-8.334V6.637c0-1.621-1.152-3.026-2.76-3.235A48.455 48.455 0 0 0 11.25 3c-2.115 0-4.198.137-6.24.402-1.608.209-2.76 1.614-2.76 3.235v6.226c0 1.621 1.152 3.026 2.76 3.235.577.075 1.157.14 1.74.194V21l4.155-4.155" />
      </svg>
    ),
    color: "text-primary",
    bgColor: "bg-primary/10",
  },
  {
    title: "Rebalance Duty Roster",
    description: "Redistribute workload for personnel exceeding 56+ hours/week duty schedules.",
    icon: (
      <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 0 1 3 19.875v-6.75ZM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V8.625ZM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 0 1-1.125-1.125V4.125Z" />
      </svg>
    ),
    color: "text-chart-3",
    bgColor: "bg-chart-3/10",
  },
  {
    title: "Medical Wellness Screening",
    description: "Schedule health assessments for personnel with concerning HRV or fatigue patterns.",
    icon: (
      <svg className="w-6 h-6" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
        <path strokeLinecap="round" strokeLinejoin="round" d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12Z" />
      </svg>
    ),
    color: "text-chart-5",
    bgColor: "bg-chart-5/10",
  },
];

export default function ActionsPage() {
  const { role } = useAuth();
  const router = useRouter();
  const [entries, setEntries] = useState<TriageEntry[]>([]);
  const [recommendations, setRecommendations] = useState<Recommendation[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (role === "Commander") {
      router.push("/overview");
    } else {
      loadData();
    }
  }, [role, router]);

  const loadData = async () => {
    try {
      const [triageData, recData] = await Promise.all([
        api.getTriage(),
        api.getOutgoingRecommendations().catch(() => []),
      ]);
      setEntries(triageData);
      setRecommendations(recData);
    } catch (err) {
      console.error("Failed to load:", err);
    } finally {
      setLoading(false);
    }
  };

  const handleAction = async (assessmentId: string, status: string) => {
    try {
      await api.takeAction(assessmentId, status);
      await loadData();
    } catch (err) {
      console.error("Action failed:", err);
    }
  };

  const pending = entries.filter((e) => e.status === "Pending");
  const acknowledged = entries.filter((e) => e.status === "Acknowledged");
  const completed = entries.filter((e) => e.status === "Action_Taken");

  const pendingRecs = recommendations.filter((r) => r.status === "Pending");
  const reviewedRecs = recommendations.filter((r) => r.status === "Reviewed");
  const actionedRecs = recommendations.filter((r) => r.status === "Actioned");

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
        <h1 className="text-2xl font-bold tracking-tight">Intervention Actions</h1>
        <p className="text-muted-foreground text-[13px] mt-1.5 leading-relaxed">
          Execute welfare recommendations and track intervention progress
        </p>
      </div>

      {/* Quick Action Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5">
        {ACTION_CARDS.map((card, i) => (
          <Card
            key={i}
            className="glass-card hover:bg-accent/30 transition-all duration-200 cursor-pointer group animate-slide-up"
            style={{ animationDelay: `${i * 0.1}s` }}
          >
            <CardContent className="pt-6">
              <div className={`w-12 h-12 rounded-xl ${card.bgColor} flex items-center justify-center ${card.color} mb-4 group-hover:scale-110 transition-transform`}>
                {card.icon}
              </div>
              <h3 className="font-semibold text-[14px] mb-1.5">{card.title}</h3>
              <p className="text-[13px] text-muted-foreground leading-relaxed">{card.description}</p>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Pending Recommendations */}
      <div className="space-y-3">
        <div className="flex items-center gap-2">
          <h2 className="text-lg font-semibold">Pending Recommendations</h2>
          <Badge variant="outline" className="text-[11px]">{pending.length}</Badge>
        </div>
        {pending.length === 0 ? (
          <Card className="glass-card">
            <CardContent className="py-8 text-center text-muted-foreground text-[13px]">
              All recommendations have been addressed. ✓
            </CardContent>
          </Card>
        ) : (
          pending.slice(0, 10).map((entry, i) => {
            const risk = riskConfig[entry.risk_level] || riskConfig.Routine;
            return (
              <Card key={entry.assessment_id} className="glass-card animate-slide-up" style={{ animationDelay: `${i * 0.05}s` }}>
                <CardContent className="py-4">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-3">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[12px] font-semibold border ${risk.class}`}>
                        {risk.label}
                      </span>
                      <span className="text-[13px] font-medium">{entry.full_name}</span>
                      <span className="text-[12px] text-muted-foreground">{entry.unit}</span>
                    </div>
                    <div className="flex gap-2">
                      <button
                        onClick={() => handleAction(entry.assessment_id, "Acknowledged")}
                        className="px-3.5 py-1.5 rounded-md bg-primary/10 text-primary text-[12px] font-medium hover:bg-primary/20 transition-colors cursor-pointer"
                      >
                        Acknowledge
                      </button>
                      <button
                        onClick={() => handleAction(entry.assessment_id, "Action_Taken")}
                        className="px-3.5 py-1.5 rounded-md bg-risk-routine/10 text-risk-routine text-[12px] font-medium hover:bg-risk-routine/20 transition-colors cursor-pointer"
                      >
                        Complete
                      </button>
                    </div>
                  </div>
                  <p className="text-[13px] text-muted-foreground mt-2.5 leading-relaxed">{entry.recommended_intervention}</p>
                </CardContent>
              </Card>
            );
          })
        )}
      </div>

      {/* ── Sent to Commanding Officer ─────────────────────────────────────── */}
      {recommendations.length > 0 && (
        <div className="space-y-4">
          <div className="flex items-center gap-3">
            <div className="w-8 h-8 rounded-lg bg-amber-500/15 border border-amber-500/25 flex items-center justify-center">
              <svg className="w-4 h-4 text-amber-400" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 12 3.269 3.125A59.769 59.769 0 0 1 21.485 12 59.768 59.768 0 0 1 3.27 20.875L5.999 12Zm0 0h7.5" />
              </svg>
            </div>
            <div>
              <h2 className="text-lg font-semibold">Sent to Commanding Officer</h2>
              <p className="text-[12px] text-muted-foreground">Soldiers you've recommended for CO attention</p>
            </div>
            <div className="ml-auto flex items-center gap-2">
              <Badge variant="outline" className="text-[11px] text-amber-400 border-amber-500/30">{pendingRecs.length} pending</Badge>
              <Badge variant="outline" className="text-[11px] text-sky-400 border-sky-500/30">{reviewedRecs.length} reviewed</Badge>
              <Badge variant="outline" className="text-[11px] text-emerald-400 border-emerald-500/30">{actionedRecs.length} actioned</Badge>
            </div>
          </div>

          <div className="space-y-3">
            {recommendations.map((rec, i) => {
              const risk = riskConfig[rec.risk_level] || riskConfig.Routine;
              const statusCfg = recStatusConfig[rec.status] || recStatusConfig.Pending;
              const timeAgo = getTimeAgo(rec.created_at);

              return (
                <Card
                  key={rec.id}
                  className="glass-card animate-slide-up hover:bg-accent/20 transition-colors"
                  style={{ animationDelay: `${i * 0.05}s` }}
                >
                  <CardContent className="py-4">
                    <div className="flex flex-col lg:flex-row lg:items-start gap-4">
                      {/* Soldier info */}
                      <div className="flex items-center gap-3 lg:w-52 shrink-0">
                        <div className={`w-9 h-9 rounded-full flex items-center justify-center text-sm font-bold border ${risk.class}`}>
                          {rec.soldier_name.charAt(0)}
                        </div>
                        <div>
                          <p className="font-medium text-[13px]">{rec.soldier_name}</p>
                          <p className="text-[11px] text-muted-foreground">{rec.soldier_service_id} • {rec.unit_name}</p>
                        </div>
                      </div>

                      {/* Risk + Status */}
                      <div className="flex items-center gap-2 lg:w-48 shrink-0">
                        <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-semibold border ${risk.class}`}>
                          {risk.label}
                        </span>
                        <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-semibold border ${statusCfg.bgColor} ${statusCfg.color}`}>
                          {statusCfg.label}
                        </span>
                      </div>

                      {/* Note */}
                      <div className="flex-1 min-w-0 space-y-2">
                        <p className="text-[13px] text-muted-foreground leading-relaxed">
                          <span className="font-medium text-foreground/90">Your note:</span> {rec.note}
                        </p>
                        {rec.commander_response && (
                          <div className="flex items-start gap-2 p-2.5 rounded-lg bg-sky-500/5 border border-sky-500/15">
                            <svg className="w-4 h-4 text-sky-400 mt-0.5 shrink-0" fill="none" viewBox="0 0 24 24" strokeWidth="1.5" stroke="currentColor">
                              <path strokeLinecap="round" strokeLinejoin="round" d="M7.5 8.25h9m-9 3H12m-9.75 1.51c0 1.6 1.123 2.994 2.707 3.227 1.129.166 2.27.293 3.423.379.35.026.67.21.865.501L12 21l2.755-4.133a1.14 1.14 0 0 1 .865-.501 48.172 48.172 0 0 0 3.423-.379c1.584-.233 2.707-1.626 2.707-3.228V6.741c0-1.602-1.123-2.995-2.707-3.228A48.394 48.394 0 0 0 12 3c-2.392 0-4.744.175-7.043.513C3.373 3.746 2.25 5.14 2.25 6.741v6.018Z" />
                            </svg>
                            <div>
                              <p className="text-[11px] font-medium text-sky-400">CO Response — {rec.commander_name}</p>
                              <p className="text-[12px] text-muted-foreground mt-0.5">{rec.commander_response}</p>
                            </div>
                          </div>
                        )}
                      </div>

                      {/* Time */}
                      <div className="text-[11px] text-muted-foreground shrink-0 lg:text-right">
                        {timeAgo}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        </div>
      )}

      {/* Completed actions summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <Card className="glass-card">
          <CardContent className="py-6 text-center">
            <p className="text-3xl font-bold text-risk-intervention">{pending.length}</p>
            <p className="text-sm text-muted-foreground mt-1.5">Pending</p>
          </CardContent>
        </Card>
        <Card className="glass-card">
          <CardContent className="py-6 text-center">
            <p className="text-3xl font-bold text-risk-monitor">{acknowledged.length}</p>
            <p className="text-sm text-muted-foreground mt-1.5">In Progress</p>
          </CardContent>
        </Card>
        <Card className="glass-card">
          <CardContent className="py-6 text-center">
            <p className="text-3xl font-bold text-risk-routine">{completed.length}</p>
            <p className="text-sm text-muted-foreground mt-1.5">Completed</p>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}

function getTimeAgo(dateStr: string): string {
  const diff = Date.now() - new Date(dateStr).getTime();
  const minutes = Math.floor(diff / 60000);
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}
