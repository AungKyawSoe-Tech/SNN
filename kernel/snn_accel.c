// SPDX-License-Identifier: MIT
// Skeleton Linux platform driver for the LiteX SNN accelerator CSR interface

#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/of.h>
#include <linux/of_address.h>
#include <linux/io.h>
#include <linux/interrupt.h>
#include <linux/mutex.h>
#include <linux/uaccess.h>
#include <linux/fs.h>

#define DRIVER_NAME "litex_snn"

struct snn_accel {
    void __iomem *regs;
    int irq;
    struct mutex lock; // guards CSR accesses and state
    struct device *dev;
};

static irqreturn_t snn_irq(int irq, void *data)
{
    struct snn_accel *accel = data;
    u32 status = readl(accel->regs + 0x24); // IRQ_STATUS offset

    if (!status)
        return IRQ_NONE;

    writel(status, accel->regs + 0x24); // acknowledge
    dev_dbg(accel->dev, "irq status=0x%08x\n", status);
    return IRQ_HANDLED;
}

static int snn_probe(struct platform_device *pdev)
{
    struct snn_accel *accel;
    struct resource *res;
    int ret;

    accel = devm_kzalloc(&pdev->dev, sizeof(*accel), GFP_KERNEL);
    if (!accel)
        return -ENOMEM;

    res = platform_get_resource(pdev, IORESOURCE_MEM, 0);
    accel->regs = devm_ioremap_resource(&pdev->dev, res);
    if (IS_ERR(accel->regs))
        return PTR_ERR(accel->regs);

    accel->irq = platform_get_irq(pdev, 0);
    if (accel->irq < 0)
        return accel->irq;

    ret = devm_request_irq(&pdev->dev, accel->irq, snn_irq, 0, DRIVER_NAME, accel);
    if (ret)
        return ret;

    mutex_init(&accel->lock);
    accel->dev = &pdev->dev;
    platform_set_drvdata(pdev, accel);

    dev_info(&pdev->dev, "LiteX SNN accelerator probed\n");
    return 0;
}

static int snn_remove(struct platform_device *pdev)
{
    struct snn_accel *accel = platform_get_drvdata(pdev);

    mutex_destroy(&accel->lock);
    return 0;
}

static const struct of_device_id snn_of_match[] = {
    { .compatible = "litex,snn-accelerator" },
    { /* sentinel */ }
};
MODULE_DEVICE_TABLE(of, snn_of_match);

static struct platform_driver snn_driver = {
    .probe = snn_probe,
    .remove = snn_remove,
    .driver = {
        .name = DRIVER_NAME,
        .of_match_table = snn_of_match,
    },
};

module_platform_driver(snn_driver);

MODULE_AUTHOR("GitHub Copilot");
MODULE_DESCRIPTION("LiteX SNN accelerator driver skeleton");
MODULE_LICENSE("MIT");
