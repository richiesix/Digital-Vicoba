<?php

namespace App\Providers;

use App\Models\VicobaGroup;
use Illuminate\Support\Facades\Route;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        Route::bind('group', fn (string $value) => VicobaGroup::query()->where('id', $value)->orWhere('uuid', $value)->firstOrFail());
    }
}
