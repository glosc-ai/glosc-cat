<script setup lang="ts">
import { RouterLink } from "vue-router";
</script>

<template>
    <div class="min-h-screen bg-cream-white py-12 px-6 sm:px-12 lg:px-24">
        <div
            class="max-w-3xl mx-auto bg-white rounded-4xl p-8 sm:p-12 shadow-(--shadow-soft)">
            <div class="mb-8 flex items-center justify-between">
                <RouterLink
                    to="/"
                    class="flex items-center gap-2 text-sage-green hover:text-text-main transition-colors">
                    <span class="text-xl">←</span>
                    <span class="font-medium">返回首页</span>
                </RouterLink>
                <div class="text-text-muted text-sm">
                    更新日期：2025年5月20日
                </div>
            </div>

            <h1 class="font-cute text-4xl text-center mb-10 text-text-main">
                说猫语 - 隐私政策
            </h1>

            <div
                class="prose prose-slate max-w-none text-text-main leading-loose">
                <section class="mb-8">
                    <h2 class="font-cute text-2xl mb-4 text-peach-pink">
                        1. 引言 🐾
                    </h2>
                    <p>
                        欢迎使用“说猫语”（以下简称“本应用”）。我们深知隐私对您的重要性，并致力于保护您和您爱宠的个人信息。本隐私政策旨在向您说明本应用如何收集、使用、存储及保护您的信息。
                    </p>
                </section>

                <section class="mb-8">
                    <h2 class="font-cute text-2xl mb-4 text-peach-pink">
                        2. 我们收集的信息 🐱
                    </h2>
                    <p>
                        为了提供猫语分析和人语转换功能，本应用在您授权的前提下，仅收集实现功能所必需的最少信息：
                    </p>
                    <ul class="list-disc pl-6 mt-2 space-y-2">
                        <li>
                            <strong>麦克风权限与音频数据：</strong
                            >当您使用“猫语转人话”或录制声音时，我们需要获取麦克风权限。录制的音频数据仅用于本地处理，不会上传至任何云端服务器。
                        </li>
                        <li>
                            <strong>使用数据：</strong
                            >我们可能会收集匿名的基础使用数据（如功能点击次数），以帮助我们优化应用体验。这些数据不包含任何可识别您身份的信息。
                        </li>
                    </ul>
                </section>

                <section class="mb-8">
                    <h2 class="font-cute text-2xl mb-4 text-peach-pink">
                        3. 信息的存储与安全 🔒
                    </h2>
                    <p>
                        <strong>本地处理原则：</strong
                        >本应用的核心音频分析和特征比对均在您的设备本地完成。您的录音数据、互动记录和收藏短语均通过本地数据库（如
                        SwiftData）存储在您的设备中。
                    </p>
                    <p class="mt-2">
                        我们不会将您的个人音频数据或互动记录上传、备份或分享给任何第三方。只要您不卸载应用或主动清除数据，这些记录将安全地保存在您的手机中。
                    </p>
                </section>

                <section class="mb-8">
                    <h2 class="font-cute text-2xl mb-4 text-peach-pink">
                        4. 第三方服务 🤝
                    </h2>
                    <p>
                        目前本应用未接入任何涉及共享您核心个人信息的第三方
                        SDK。如果在未来版本中我们需要引入第三方服务（如匿名崩溃日志收集工具），我们将提前更新本政策并在此说明。
                    </p>
                </section>

                <section class="mb-8">
                    <h2 class="font-cute text-2xl mb-4 text-peach-pink">
                        5. 您的权利 🛡️
                    </h2>
                    <p>您可以随时通过以下方式管理您的信息：</p>
                    <ul class="list-disc pl-6 mt-2 space-y-2">
                        <li>在系统设置中撤销本应用的麦克风权限。</li>
                        <li>
                            在应用内主动删除单条互动记录或清空所有历史数据。
                        </li>
                        <li>通过卸载本应用来清除所有相关的本地存储数据。</li>
                    </ul>
                </section>

                <section class="mb-8">
                    <h2 class="font-cute text-2xl mb-4 text-peach-pink">
                        6. 儿童隐私 👼
                    </h2>
                    <p>
                        本应用主要面向成人（尤其是年轻的养宠人群）。如果您是未成年人，请在父母或法定监护人的指导下使用本应用。我们不会主动收集未成年人的个人信息。
                    </p>
                </section>

                <section class="mb-8">
                    <h2 class="font-cute text-2xl mb-4 text-peach-pink">
                        7. 政策更新 📝
                    </h2>
                    <p>
                        我们可能会适时对本隐私政策进行修订。当条款发生重大变更时，我们会在您登录或更新应用时以弹窗或通知的形式向您展示变更后的内容。
                    </p>
                </section>

                <section class="mb-8">
                    <h2 class="font-cute text-2xl mb-4 text-peach-pink">
                        8. 联系我们 💌
                    </h2>
                    <p>
                        如果您对本隐私政策有任何疑问、意见或建议，请随时通过以下方式与我们联系：
                    </p>
                    <p class="mt-2">
                        电子邮箱：<a
                            href="mailto:xm@aoe.top"
                            class="text-sage-green hover:underline"
                            >xm@aoe.top</a
                        >
                    </p>
                </section>
            </div>

            <div
                class="mt-16 pt-8 border-t border-oat-apricot text-center text-text-muted text-sm">
                <p>© 2025 说猫语. All rights reserved.</p>
            </div>
        </div>
    </div>
</template>
