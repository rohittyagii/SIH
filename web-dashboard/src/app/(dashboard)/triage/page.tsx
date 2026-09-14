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
                    <div className="flex items-center gap-2 shrink-0" onClick={(e) => e.stopPropagation()}>
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
                    </div>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
