import React from 'react';

export const StatusBadge = ({ status }) => {
    const styles = {
        Active: 'bg-emerald-500/10 text-emerald-400 border-emerald-500/20',
        Expired: 'bg-red-500/10 text-red-400 border-red-500/20',
        Pending: 'bg-amber-500/10 text-amber-400 border-amber-500/20',
        Closed: 'bg-[var(--surface-glass)] text-[var(--text-secondary)] border-[var(--border)]',
        Verified: 'bg-blue-500/10 text-blue-400 border-blue-500/20',
    };

    return (
        <span className={`badge border ${styles[status] || styles.Pending}`}>
            {status}
        </span>
    );
};

export const SectionCard = ({ title, children, icon: Icon, action }) => (
    <div className="card glass p-6 space-y-6">
        <div className="flex items-center justify-between border-b border-[var(--border)] pb-4">
            <div className="flex items-center space-x-3">
                {Icon && (
                    <div className="w-10 h-10 bg-[var(--surface-glass)] rounded-xl flex items-center justify-center text-[var(--primary)] border border-[var(--border)] shadow-inner">
                        <Icon size={20} />
                    </div>
                )}
                <h3 className="font-bold text-[var(--text-primary)] tracking-tight">{title}</h3>
            </div>
            {action}
        </div>
        <div className="space-y-6">
            {children}
        </div>
    </div>
);

export const ToggleSwitch = ({ label, enabled, onChange }) => (
    <div className="flex items-center justify-between py-2">
        {label && <span className="text-sm font-bold text-[var(--text-secondary)]">{label}</span>}
        <button
            type="button"
            onClick={() => onChange(!enabled)}
            className={`relative inline-flex h-6 w-11 shrink-0 cursor-pointer rounded-full border-2 border-transparent transition-colors duration-200 ease-in-out focus:outline-none ${enabled ? 'bg-[var(--primary)]' : 'bg-[var(--border)]'
                }`}
        >
            <span
                aria-hidden="true"
                className={`pointer-events-none inline-block h-5 w-5 transform rounded-full bg-white shadow ring-0 transition duration-200 ease-in-out ${enabled ? 'translate-x-5' : 'translate-x-0'
                    }`}
            />
        </button>
    </div>
);
