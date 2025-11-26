📌 Overview

This repository contains a SQL query that aggregates subscription data on a daily basis from the dbo.Subscriptions table and produces:

simple numeric metrics (active, active_free, active_non_free)

and a structured JSON field (detail) for downstream systems.

The aggregation is done by:

date (Gregorian and Persian)

SubscriptionPlanId

Payment_Gateway

ThirdPartyId



🎯 Purpose

The main goals of this query are:

Compute the total number of active subscriptions on a given target date.

Split active subscriptions into:

active – total number of active subscriptions

active_free – active subscriptions with EffectiveAmount = 0

active_non_free – active subscriptions with EffectiveAmount > 0

Provide a structured JSON payload (detail) that breaks down:

active_non_free counts per (subscription_plan_id, gateway, thirdparty_id)
(excluding gateway = 0 or NULL inside the JSON)

active_free counts per the same key (all gateways included)

This JSON is intended to be consumed by automation tools (such as n8n) and internal services.


🧱 Data Source

dbo.Subscriptions – core subscription data

[Common].[Calendar] – date mapping between Gregorian and Persian calendar



📦 Query Structure

The query uses three main CTEs:

ActiveSubs – filters and prepares currently active subscriptions for @TargetDate

Cal – resolves Gregorian and Persian date components for the target date

Agg – performs the aggregation by subscription_plan_id, gateway, and thirdparty_id, and prepares the metrics and JSON key

The final SELECT aggregates per day and builds the detail JSON object.


🔧 Notes

The script assumes appropriate indexing on ActiveFrom, ActiveTo, Status, IsDeleted, SubscriptionPlanId, Payment_GateWay, and ThirdPartyId.

The JSON payload is designed for daily jobs and downstream processing rather than direct end-user visualization.
